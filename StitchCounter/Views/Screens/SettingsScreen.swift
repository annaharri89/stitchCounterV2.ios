import SwiftUI
import UniformTypeIdentifiers

private let privacyPolicyURL = URL(string: "https://harrisonsoftware.dev/stitch-counter/privacy-policy")!
private let bugReportEmail = "support@harrisonsoftware.dev"

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var isThemeSectionExpanded = true
    @State private var isBackupSectionExpanded = true
    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var exportURL: URL?

    @Environment(\.themeColors) private var colors
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                themeSection
                backupSection
                supportSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
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
        .alert("Import Complete", isPresented: $viewModel.importSuccess) {
            Button("OK") {
                viewModel.clearImportStatus()
            }
        } message: {
            VStack {
                Text("Imported \(viewModel.importedCount) project(s)")
                if viewModel.failedCount > 0 {
                    Text("Failed to import \(viewModel.failedCount) project(s)")
                }
            }
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isThemeSectionExpanded) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: viewModel.selectedTheme == theme,
                        onSelect: { viewModel.onThemeSelected(theme) }
                    )
                }
            } label: {
                Label("Theme Settings", systemImage: "paintpalette")
                    .font(.headline)
            }
        }
    }

    // MARK: - Backup & Restore

    private var backupSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isBackupSectionExpanded) {
                VStack(spacing: 12) {
                    Button {
                        exportLibrary()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(viewModel.isExporting ? "Exporting..." : "Export Library")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colors.primary)
                        .foregroundColor(colors.onPrimary)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isExporting || viewModel.isImporting)

                    if let error = viewModel.exportError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(colors.error)
                    }

                    Button {
                        showImportPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text(viewModel.isImporting ? "Importing..." : "Import Library")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colors.secondary)
                        .foregroundColor(colors.onSecondary)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isExporting || viewModel.isImporting)

                    if let error = viewModel.importError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(colors.error)
                    }
                }
                .padding(.vertical, 8)
            } label: {
                Label("Backup & Restore", systemImage: "externaldrive")
                    .font(.headline)
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        Section {
            Button {
                if let mailURL = URL(string: "mailto:\(bugReportEmail)?subject=Stitch%20Counter%20Bug%20Report") {
                    openURL(mailURL)
                }
            } label: {
                Label("Report a Bug", systemImage: "ladybug")
            }

            Button {
                openURL(privacyPolicyURL)
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
        } header: {
            Text("Support")
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
}

// MARK: - Theme Option Row

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.themeColors) private var colors

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundColor(colors.onSurface)

                    if isSelected {
                        themeColorPreviews
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface.opacity(0.4))
            }
            .padding(.vertical, 8)
        }
    }

    private var themeColorPreviews: some View {
        let previewColors = ThemeManager.colors(for: theme, isDark: false)
        return HStack(spacing: 8) {
            Circle().fill(previewColors.primary).frame(width: 20, height: 20)
            Circle().fill(previewColors.secondary).frame(width: 20, height: 20)
            Circle().fill(previewColors.tertiary).frame(width: 20, height: 20)
            Circle().fill(previewColors.quaternary).frame(width: 20, height: 20)
        }
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
