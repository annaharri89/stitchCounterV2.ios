import SwiftUI
import PhotosUI

struct ProjectDetailScreen: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    let projectId: UUID?
    let projectType: ProjectType?
    let isNewProject: Bool
    let onDismiss: () -> Void
    let onProjectCreated: ((UUID) -> Void)?
    let onNavigateBack: ((UUID) -> Void)?
    
    @State private var showDiscardDialog = false
    @Environment(\.themeColors) private var colors
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isTotalRowsFocused: Bool
    
    init(
        viewModel: ProjectDetailViewModel,
        projectId: UUID?,
        projectType: ProjectType?,
        onDismiss: @escaping () -> Void,
        onProjectCreated: ((UUID) -> Void)? = nil,
        onNavigateBack: ((UUID) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.projectId = projectId
        self.projectType = projectType
        self.isNewProject = projectId == nil
        self.onDismiss = onDismiss
        self.onProjectCreated = onProjectCreated
        self.onNavigateBack = onNavigateBack
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleField
                    
                    if viewModel.projectType == .double {
                        totalRowsField
                        
                        if let project = viewModel.project, project.totalRows > 0 {
                            RowProgressView(
                                currentRowCount: project.rowCounterNumber,
                                totalRows: project.totalRows
                            )
                        }
                    }
                    
                    ProjectImageSelectorView(
                        imagePaths: viewModel.imagePaths,
                        onAddImage: { viewModel.addImage($0) },
                        onRemoveImage: { viewModel.removeImagePath($0) }
                    )
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle(isNewProject ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isNewProject {
                            viewModel.attemptDismissal()
                        } else if let projectId = viewModel.project?.id, let onNavigateBack = onNavigateBack {
                            onNavigateBack(projectId)
                        } else {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: isNewProject ? "xmark" : "chevron.left")
                    }
                }
                
                if isNewProject {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Create") {
                            createProject()
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isNewProject && isFormValid {
                    Button {
                        createProject()
                    } label: {
                        Text("Create Project")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.primary)
                            .foregroundColor(colors.onPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            if let projectId = projectId {
                viewModel.loadProjectById(projectId)
            } else if let projectType = projectType {
                viewModel.loadProject(nil, projectType: projectType)
            }
        }
        .onChange(of: viewModel.dismissalResult) { _, newValue in
            switch newValue {
            case .allowed:
                onDismiss()
            case .showDiscardDialog:
                showDiscardDialog = true
            case .blocked, .none:
                break
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardDialog) {
            Button("Cancel", role: .cancel) {
                viewModel.dismissalResult = nil
            }
            Button("Discard", role: .destructive) {
                viewModel.discardChanges()
                onDismiss()
            }
        } message: {
            Text(viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty
                 ? "Project title is required. Do you want to discard this project?"
                 : "You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Project Title")
                .font(.subheadline)
                .foregroundColor(colors.onSurface.opacity(0.6))
            
            TextField("Enter project title", text: Binding(
                get: { viewModel.title },
                set: { viewModel.updateTitle($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($isTitleFocused)
            .submitLabel(viewModel.projectType == .double ? .next : .done)
            .onSubmit {
                if viewModel.projectType == .double {
                    isTotalRowsFocused = true
                }
            }
            
            if let error = viewModel.titleError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(colors.error)
            }
        }
    }
    
    private var totalRowsField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Rows")
                .font(.subheadline)
                .foregroundColor(colors.onSurface.opacity(0.6))
            
            TextField("Enter total rows", text: Binding(
                get: { viewModel.totalRows },
                set: { viewModel.updateTotalRows($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .focused($isTotalRowsFocused)
            
            if let error = viewModel.totalRowsError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(colors.error)
            }
        }
    }
    
    private var isFormValid: Bool {
        let titleValid = !viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty
        let totalRowsValid = viewModel.projectType != .double || (Int(viewModel.totalRows) ?? 0) > 0
        return titleValid && totalRowsValid
    }
    
    private func createProject() {
        if let newProjectId = viewModel.createProject() {
            onProjectCreated?(newProjectId)
        }
    }
}

#Preview {
    ProjectDetailScreen(
        viewModel: ProjectDetailViewModel(projectService: ProjectService()),
        projectId: nil,
        projectType: .single,
        onDismiss: {}
    )
}
