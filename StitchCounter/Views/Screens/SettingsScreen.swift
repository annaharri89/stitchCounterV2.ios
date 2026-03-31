import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum SettingsActionColorStyle {
    case primary
    case secondary
    case tertiary

    func backgroundColor(using themeColors: ThemeColors) -> Color {
        switch self {
        case .primary: return themeColors.primary
        case .secondary: return themeColors.secondary
        case .tertiary: return themeColors.tertiary
        }
    }

    func foregroundColor(using themeColors: ThemeColors) -> Color {
        switch self {
        case .primary: return themeColors.onPrimary
        case .secondary: return themeColors.onSecondary
        case .tertiary: return themeColors.onTertiary
        }
    }
}

protocol SettingsActionOption: CaseIterable, Identifiable, Hashable {
    var titleLocalizationKey: String { get }
    var systemImage: String { get }
    var accessibilityHintLocalizationKey: String { get }
    var colorStyle: SettingsActionColorStyle { get }
}

extension SettingsActionOption where Self: Hashable {
    var id: Self { self }

    func backgroundColor(_ themeColors: ThemeColors) -> Color {
        colorStyle.backgroundColor(using: themeColors)
    }

    func foregroundColor(_ themeColors: ThemeColors) -> Color {
        colorStyle.foregroundColor(using: themeColors)
    }
}

enum BackupRestoreOption: CaseIterable {
    case export
    case importLibrary

    var systemImage: String {
        switch self {
        case .export: return "square.and.arrow.up"
        case .importLibrary: return "square.and.arrow.down"
        }
    }

    var accessibilityHintLocalizationKey: String {
        switch self {
        case .export: return "settings.backup.export.hint"
        case .importLibrary: return "settings.backup.import.hint"
        }
    }

    var titleLocalizationKey: String {
        switch self {
        case .export: return "settings.backup.export.title"
        case .importLibrary: return "settings.backup.import.title"
        }
    }

    var colorStyle: SettingsActionColorStyle {
        switch self {
        case .export: return .primary
        case .importLibrary: return .secondary
        }
    }

    func displayTitleLocalizationKey(isExporting: Bool, isImporting: Bool) -> String {
        switch self {
        case .export: return isExporting ? "settings.backup.exporting.title" : titleLocalizationKey
        case .importLibrary: return isImporting ? "settings.backup.importing.title" : titleLocalizationKey
        }
    }

    func errorMessage(exportError: String?, importError: String?) -> String? {
        switch self {
        case .export: return exportError
        case .importLibrary: return importError
        }
    }
}

extension BackupRestoreOption: SettingsActionOption {}

enum SupportOption: CaseIterable {
    case reportBug
    case giveFeedback
    case requestFeature

    var titleLocalizationKey: String {
        switch self {
        case .reportBug: return "settings.support.reportBug.title"
        case .giveFeedback: return "settings.support.giveFeedback.title"
        case .requestFeature: return "settings.support.requestFeature.title"
        }
    }

    var systemImage: String {
        switch self {
        case .reportBug: return "ladybug"
        case .giveFeedback: return "envelope"
        case .requestFeature: return "wand.and.stars"
        }
    }

    var accessibilityHintLocalizationKey: String {
        switch self {
        case .reportBug: return "settings.support.reportBug.hint"
        case .giveFeedback: return "settings.support.giveFeedback.hint"
        case .requestFeature: return "settings.support.requestFeature.hint"
        }
    }

    var colorStyle: SettingsActionColorStyle {
        switch self {
        case .reportBug: return .primary
        case .giveFeedback: return .secondary
        case .requestFeature: return .tertiary
        }
    }
}

extension SupportOption: SettingsActionOption {}

enum PrivacyAndLegalOption: CaseIterable {
    case privacyPolicy
    case eula

    var titleLocalizationKey: String {
        switch self {
        case .privacyPolicy: return "settings.legal.privacyPolicy.title"
        case .eula: return "settings.legal.eula.title"
        }
    }

    var systemImage: String {
        switch self {
        case .privacyPolicy: return "hand.raised"
        case .eula: return "doc.text"
        }
    }

    var accessibilityHintLocalizationKey: String {
        switch self {
        case .privacyPolicy: return "settings.legal.privacyPolicy.hint"
        case .eula: return "settings.legal.eula.hint"
        }
    }

    var colorStyle: SettingsActionColorStyle {
        switch self {
        case .privacyPolicy: return .primary
        case .eula: return .secondary
        }
    }
}

extension PrivacyAndLegalOption: SettingsActionOption {}

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var isThemeSectionExpanded = false
    @State private var isBackupSectionExpanded = false
    @State private var isSupportSectionExpanded = false
    @State private var isLegalSectionExpanded = false
    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var showMailUnavailableAlert = false
    @State private var pendingSupportSubject = ""
    @State private var exportURL: URL?

    @Environment(\.themeColors) private var colors
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                themeSection
                backupSection
                supportSection
                privacyAndLegalSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings.title")
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [UTType.json],
            onCompletion: handleImport
        )
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("settings.import.complete.title", isPresented: $viewModel.importSuccess) {
            Button("common.ok") {
                viewModel.clearImportStatus()
            }
        } message: {
            VStack {
                Text(
                    String(
                        format: String(localized: "settings.import.complete.importedCount"),
                        Int64(viewModel.importedCount)
                    )
                )
                if viewModel.failedCount > 0 {
                    Text(
                        String(
                            format: String(localized: "settings.import.complete.failedCount"),
                            Int64(viewModel.failedCount)
                        )
                    )
                }
            }
        }
        .alert("settings.support.mailUnavailable.title", isPresented: $showMailUnavailableAlert) {
            Button("settings.support.mailUnavailable.copyEmail") {
                UIPasteboard.general.string = AppConstants.supportEmail
            }
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(
                String(
                    format: String(localized: "settings.support.mailUnavailable.message"),
                    AppConstants.supportEmail,
                    pendingSupportSubject
                )
            )
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isThemeSectionExpanded) {
                Text("settings.theme.chooseScheme")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: viewModel.selectedTheme == theme,
                        onSelect: { viewModel.onThemeSelected(theme) }
                    )
                }
            } label: {
                Label("settings.theme.sectionTitle", systemImage: "paintpalette")
                    .font(.headline)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Backup & Restore

    private var backupSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isBackupSectionExpanded) {
                VStack(spacing: 12) {
                    ForEach(BackupRestoreOption.allCases) { option in
                        SettingsActionButton(
                            titleLocalizationKey: option.displayTitleLocalizationKey(
                                isExporting: viewModel.isExporting,
                                isImporting: viewModel.isImporting
                            ),
                            systemImage: option.systemImage,
                            backgroundColor: option.backgroundColor(colors),
                            foregroundColor: option.foregroundColor(colors),
                            accessibilityHintLocalizationKey: option.accessibilityHintLocalizationKey,
                            isDisabled: viewModel.isExporting || viewModel.isImporting
                        ) {
                            handleBackupAction(option)
                        }

                        if let error = option.errorMessage(
                            exportError: viewModel.exportError,
                            importError: viewModel.importError
                        ) {
                            Text(
                                String(
                                    format: String(localized: "common.error.prefixed"),
                                    error
                                )
                            )
                                .font(.caption)
                                .foregroundColor(colors.error)
                        }
                    }
                }
                .padding(.vertical, 16)
            } label: {
                Label("settings.backup.sectionTitle", systemImage: "externaldrive")
                    .font(.headline)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isSupportSectionExpanded) {
                VStack(spacing: 12) {
                    ForEach(SupportOption.allCases) { option in
                        SettingsActionButton(
                            titleLocalizationKey: option.titleLocalizationKey,
                            systemImage: option.systemImage,
                            backgroundColor: option.backgroundColor(colors),
                            foregroundColor: option.foregroundColor(colors),
                            accessibilityHintLocalizationKey: option.accessibilityHintLocalizationKey
                        ) {
                            handleSupportAction(option)
                        }
                    }
                }
                .padding(.vertical, 16)
            } label: {
                Label("settings.support.sectionTitle", systemImage: "questionmark.circle")
                    .font(.headline)
                    .accessibilityLabel("settings.support.sectionAccessibilityLabel")
                    .accessibilityHint("settings.support.sectionAccessibilityHint")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Privacy & Legal

    private var privacyAndLegalSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isLegalSectionExpanded) {
                VStack(spacing: 12) {
                    ForEach(PrivacyAndLegalOption.allCases) { option in
                        SettingsActionButton(
                            titleLocalizationKey: option.titleLocalizationKey,
                            systemImage: option.systemImage,
                            backgroundColor: option.backgroundColor(colors),
                            foregroundColor: option.foregroundColor(colors),
                            accessibilityHintLocalizationKey: option.accessibilityHintLocalizationKey
                        ) {
                            handleLegalAction(option)
                        }
                    }
                }
                .padding(.vertical, 16)
            } label: {
                Label("settings.legal.sectionTitle", systemImage: "checkmark.shield")
                    .font(.headline)
                    .accessibilityLabel("settings.legal.sectionAccessibilityLabel")
                    .accessibilityHint("settings.legal.sectionAccessibilityHint")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private func exportLibrary() {
        Task {
            if let url = await viewModel.exportLibrary() {
                exportURL = url
                showExportShare = true
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            Task {
                await viewModel.importLibrary(from: url)
            }
        case .failure(let error):
            viewModel.importError = error.localizedDescription
        }
    }

    private func handleBackupAction(_ option: BackupRestoreOption) {
        switch option {
        case .export: exportLibrary()
        case .importLibrary: showImportPicker = true
        }
    }

    private func handleSupportAction(_ option: SupportOption) {
        switch option {
        case .reportBug: openSupportEmailURL(viewModel.onReportBug(), subject: AppConstants.bugReportSubject)
        case .giveFeedback: openSupportEmailURL(viewModel.onGiveFeedback(), subject: AppConstants.feedbackSubject)
        case .requestFeature: openSupportEmailURL(viewModel.onRequestFeature(), subject: AppConstants.featureRequestSubject)
        }
    }

    private func handleLegalAction(_ option: PrivacyAndLegalOption) {
        switch option {
        case .privacyPolicy: openDestinationURL(viewModel.onOpenPrivacyPolicy())
        case .eula: openDestinationURL(viewModel.onOpenEULA())
        }
    }

    private func openDestinationURL(_ destinationURL: URL?) {
        guard let destinationURL else { return }
        openURL(destinationURL) { accepted in
            if !accepted {
                UIApplication.shared.open(destinationURL)
            }
        }
    }

    private func openSupportEmailURL(_ destinationURL: URL?, subject: String) {
        guard let destinationURL else { return }
        openURL(destinationURL) { accepted in
            if !accepted {
                UIApplication.shared.open(destinationURL) { didOpen in
                    if !didOpen {
                        print("[SettingsScreen] Unable to open support mailto URL: \(destinationURL.absoluteString)")
                        pendingSupportSubject = subject
                        showMailUnavailableAlert = true
                    }
                }
            }
        }
    }
}

struct SettingsActionButton: View {
    let titleLocalizationKey: String
    let systemImage: String
    let backgroundColor: Color
    let foregroundColor: Color
    let accessibilityHintLocalizationKey: String
    var isDisabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: systemImage)
                Text(LocalizedStringKey(titleLocalizationKey))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(titleLocalizationKey)))
        .accessibilityHint(Text(LocalizedStringKey(accessibilityHintLocalizationKey)))
    }
}

// MARK: - Theme Option Row

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.themeColors) private var colors
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ThemeIconPreview(theme: theme, isDark: colorScheme == .dark, isSelected: isSelected)

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(theme.displayNameLocalizationKey))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)

                    if isSelected {
                        Text("settings.theme.colorsInTheme")
                            .font(.subheadline)
                            .foregroundColor(colors.onSurface.opacity(0.7))
                        ForEach(ThemeManager.displaySwatches(for: theme)) { swatch in
                            ThemeDisplaySwatchRow(swatch: swatch)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface.opacity(0.4))
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primaryContainer.opacity(0.35) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(theme.displayNameLocalizationKey)))
        .accessibilityHint(
            Text(
                isSelected
                    ? String(localized: "settings.theme.option.accessibilityHint.selected")
                    : String(localized: "settings.theme.option.accessibilityHint.select")
            )
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ThemeDisplaySwatchRow: View {
    let swatch: ThemeDisplaySwatch

    @Environment(\.themeColors) private var colors

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(swatch.light)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            Text(swatch.name)
                .font(.caption)
                .foregroundColor(colors.onSurface.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
            Circle()
                .fill(swatch.dark)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            Text("settings.theme.dark")
                .font(.caption)
                .foregroundColor(colors.onSurface.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                String(
                    format: String(localized: "settings.theme.swatchRowA11y"),
                    swatch.name
                )
            )
        )
    }
}

struct ThemeIconPreview: View {
    let theme: AppTheme
    let isDark: Bool
    var isSelected: Bool = false

    var body: some View {
        let themeColors = ThemeManager.colors(for: theme, isDark: isDark)

        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(themeColors.primaryContainer)

            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    Circle().fill(themeColors.primary).frame(width: 14, height: 14)
                    Circle().fill(themeColors.secondary).frame(width: 14, height: 14)
                }
                HStack(spacing: 3) {
                    Circle().fill(themeColors.tertiary).frame(width: 14, height: 14)
                    Circle().fill(themeColors.quaternary).frame(width: 14, height: 14)
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(
            color: isSelected ? Color.black.opacity(0.5) : Color.clear,
            radius: isSelected ? 6 : 0,
            x: 0,
            y: 0
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsScreen(
        viewModel: SettingsViewModel(
            themeService: ThemeService(),
            projectService: ProjectService()
        )
    )
}
