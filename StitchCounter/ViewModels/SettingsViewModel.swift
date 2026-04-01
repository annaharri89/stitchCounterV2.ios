import SwiftUI
import Combine
import MessageUI
import UIKit

struct MailComposePayload: Identifiable {
    let id: UUID
    let recipients: [String]
    let subject: String
    let body: String
    let attachmentData: Data?
    let attachmentMimeType: String?
    let attachmentFileName: String?

    init(
        id: UUID = UUID(),
        recipients: [String],
        subject: String,
        body: String,
        attachmentData: Data?,
        attachmentMimeType: String?,
        attachmentFileName: String?
    ) {
        self.id = id
        self.recipients = recipients
        self.subject = subject
        self.body = body
        self.attachmentData = attachmentData
        self.attachmentMimeType = attachmentMimeType
        self.attachmentFileName = attachmentFileName
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTheme: AppTheme
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportSuccess: Bool = false
    @Published var importSuccess: Bool = false
    @Published var exportErrorLocalizationKey: String?
    @Published var importErrorLocalizationKey: String?
    @Published var importResult: LibraryImportResult?
    @Published var mailComposePayload: MailComposePayload?

    private let themeService: ThemeService
    private let projectService: ProjectService
    private var themeCancellable: AnyCancellable?

    init(themeService: ThemeService, projectService: ProjectService) {
        self.themeService = themeService
        self.projectService = projectService
        self.selectedTheme = themeService.currentTheme
        themeCancellable = themeService.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.selectedTheme = theme
            }
    }

    func onThemeSelected(_ theme: AppTheme) {
        themeService.setTheme(theme)
    }

    func onLaunchingExternalActivity() {
        themeService.skipNextPendingAlternateIconApply()
    }

    func exportLibrary() async -> URL? {
        isExporting = true
        exportErrorLocalizationKey = nil
        defer { isExporting = false }
        do {
            let url = try projectService.exportLibrary()
            exportSuccess = true
            return url
        } catch {
            exportErrorLocalizationKey = Self.localizationKey(for: error)
            return nil
        }
    }

    func importLibrary(from url: URL) async {
        isImporting = true
        importErrorLocalizationKey = nil
        importSuccess = false
        importResult = nil
        defer { isImporting = false }
        do {
            let result = try projectService.importLibrary(from: url)
            importResult = result
            importSuccess = true
        } catch {
            importErrorLocalizationKey = Self.localizationKey(for: error)
        }
    }

    func clearExportStatus() {
        exportSuccess = false
        exportErrorLocalizationKey = nil
    }

    func clearImportStatus() {
        importSuccess = false
        importErrorLocalizationKey = nil
        importResult = nil
    }

    func makeBugReportMailPayload(includeDiagnostics: Bool) -> MailComposePayload? {
        guard MFMailComposeViewController.canSendMail() else { return nil }
        let body = Self.bugReportEmailBody(includeDiagnostics: includeDiagnostics)
        let attachment = includeDiagnostics ? Self.diagnosticsAttachmentData() : nil
        return MailComposePayload(
            recipients: [AppConstants.supportEmail],
            subject: AppConstants.bugReportSubject,
            body: body,
            attachmentData: attachment,
            attachmentMimeType: attachment != nil ? "text/plain" : nil,
            attachmentFileName: attachment != nil ? "stitch_counter_diagnostics.txt" : nil
        )
    }

    func makeGiveFeedbackMailPayload() -> MailComposePayload? {
        guard MFMailComposeViewController.canSendMail() else { return nil }
        return MailComposePayload(
            recipients: [AppConstants.supportEmail],
            subject: AppConstants.feedbackSubject,
            body: Self.standardDiagnosticsLines().joined(separator: "\n"),
            attachmentData: nil,
            attachmentMimeType: nil,
            attachmentFileName: nil
        )
    }

    func makeFeatureRequestMailPayload() -> MailComposePayload? {
        guard MFMailComposeViewController.canSendMail() else { return nil }
        return MailComposePayload(
            recipients: [AppConstants.supportEmail],
            subject: AppConstants.featureRequestSubject,
            body: Self.standardDiagnosticsLines().joined(separator: "\n"),
            attachmentData: nil,
            attachmentMimeType: nil,
            attachmentFileName: nil
        )
    }

    func dismissMailComposer() {
        mailComposePayload = nil
    }

    func onOpenPrivacyPolicy() -> URL? {
        URL(string: AppConstants.privacyPolicyURL)
    }

    func onOpenEULA() -> URL? {
        URL(string: AppConstants.eulaURL)
    }

    func mailtoURLForBugReport(includeDiagnostics: Bool) -> URL? {
        makeSupportEmailURL(
            with: AppConstants.bugReportSubject,
            body: Self.bugReportEmailBody(includeDiagnostics: includeDiagnostics)
        )
    }

    func mailtoURLForFeedback() -> URL? {
        makeSupportEmailURL(
            with: AppConstants.feedbackSubject,
            body: Self.standardDiagnosticsLines().joined(separator: "\n")
        )
    }

    func mailtoURLForFeatureRequest() -> URL? {
        makeSupportEmailURL(
            with: AppConstants.featureRequestSubject,
            body: Self.standardDiagnosticsLines().joined(separator: "\n")
        )
    }

    private func makeSupportEmailURL(with subject: String, body: String) -> URL? {
        let encodedSubject =
            subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(AppConstants.supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)")
    }

    private static func bugReportEmailBody(includeDiagnostics: Bool) -> String {
        var lines = standardDiagnosticsLines()
        if includeDiagnostics {
            lines.append("")
            lines.append(String(localized: "settings.bugReport.diagnosticsNote"))
        }
        return lines.joined(separator: "\n")
    }

    private static func standardDiagnosticsLines() -> [String] {
        let version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return [
            "Device: \(UIDevice.current.model)",
            "iOS: \(UIDevice.current.systemVersion)",
            "App: \(version) (\(build))",
        ]
    }

    private static func diagnosticsAttachmentData() -> Data? {
        standardDiagnosticsLines().joined(separator: "\n").data(using: .utf8)
    }

    private static func localizationKey(for error: Error) -> String {
        if let backupError = error as? LibraryBackupError {
            switch backupError {
            case .documentsDirectoryUnavailable:
                return "settings.error.storageUnavailable"
            case .cannotCreateArchive, .cannotReadArchive, .backupJsonMissing, .invalidBackupPayload:
                return "settings.error.backupInvalid"
            case .unsupportedBackupVersion:
                return "settings.error.backupUnsupportedVersion"
            case .unsafeZipEntry:
                return "settings.error.backupUnsafe"
            case .unexpectedUnderlying:
                return "settings.error.unexpected"
            case .notZipFile:
                return "settings.error.backupNotZip"
            }
        }
        return "settings.error.unexpected"
    }
}
