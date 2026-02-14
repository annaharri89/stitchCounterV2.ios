import SwiftUI
import UniformTypeIdentifiers

private let privacyPolicyURL = URL(string: "https://harrisonsoftware.dev/stitch-counter/privacy-policy")!
private let bugReportEmail = "support@harrisonsoftware.dev"

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var isBackupSectionExpanded = true
    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var exportURL: URL?

    @Environment(\.themeColors) private var colors
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
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
            projectService: ProjectService()
        )
    )
}
