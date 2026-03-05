import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTheme: AppTheme
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportSuccess: Bool = false
    @Published var importSuccess: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var importedCount: Int = 0
    @Published var failedCount: Int = 0
    
    private let themeService: ThemeService
    private let projectService: ProjectService
    
    init(themeService: ThemeService, projectService: ProjectService) {
        self.themeService = themeService
        self.projectService = projectService
        self.selectedTheme = themeService.currentTheme
    }
    
    func onThemeSelected(_ theme: AppTheme) {
        selectedTheme = theme
        themeService.setTheme(theme)
    }
    
    func exportLibrary() async -> URL? {
        isExporting = true
        exportError = nil
        defer { isExporting = false }
        
        do {
            let url = try projectService.exportLibrary()
            exportSuccess = true
            return url
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }
    
    func importLibrary(from url: URL) async {
        isImporting = true
        importError = nil
        importedCount = 0
        failedCount = 0
        defer { isImporting = false }
        
        do {
            let result = try projectService.importLibrary(from: url)
            importedCount = result.importedCount
            failedCount = result.failedCount
            importSuccess = true
        } catch {
            importError = error.localizedDescription
        }
    }
    
    func clearExportStatus() {
        exportSuccess = false
        exportError = nil
    }
    
    func clearImportStatus() {
        importSuccess = false
        importError = nil
        importedCount = 0
        failedCount = 0
    }

    func onReportBug() -> URL? {
        makeSupportEmailURL(with: AppConstants.bugReportSubject)
    }

    func onGiveFeedback() -> URL? {
        makeSupportEmailURL(with: AppConstants.feedbackSubject)
    }

    func onRequestFeature() -> URL? {
        makeSupportEmailURL(with: AppConstants.featureRequestSubject)
    }

    func onOpenPrivacyPolicy() -> URL? {
        URL(string: AppConstants.privacyPolicyURL)
    }

    func onOpenEULA() -> URL? {
        URL(string: AppConstants.eulaURL)
    }

    private func makeSupportEmailURL(with subject: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        return URL(string: "mailto:\(AppConstants.supportEmail)?subject=\(encodedSubject)")
    }
}
