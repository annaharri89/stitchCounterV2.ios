import SwiftUI

struct ProjectDetailScreen: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    let projectId: UUID?
    let projectType: ProjectType?
    private let beganAsNewProjectSheet: Bool
    let onDismiss: () -> Void
    let onNavigateBack: ((UUID) -> Void)?
    /// Called after a new project is successfully created from the draft sheet (e.g. navigate to counter).
    let onProjectCreated: ((UUID) -> Void)?
    
    @State private var showDiscardDialog = false
    @State private var showImagePreview = false
    @State private var imagePreviewStartIndex = 0
    @State private var suppressScrollForPhotoReorder = false
    @Environment(\.themeColors) private var colors
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case title
        case totalRows
    }
    
    init(
        viewModel: ProjectDetailViewModel,
        projectId: UUID?,
        projectType: ProjectType?,
        onDismiss: @escaping () -> Void,
        onNavigateBack: ((UUID) -> Void)? = nil,
        onProjectCreated: ((UUID) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.projectId = projectId
        self.projectType = projectType
        self.beganAsNewProjectSheet = projectId == nil
        self.onDismiss = onDismiss
        self.onNavigateBack = onNavigateBack
        self.onProjectCreated = onProjectCreated
    }
    
    private var showsDraftChrome: Bool {
        beganAsNewProjectSheet && !viewModel.isProjectPersistedInLibrary
    }
    
    private var showsPersistedProjectExtras: Bool {
        !beganAsNewProjectSheet || viewModel.isProjectPersistedInLibrary
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleField
                    
                    if viewModel.projectType == .double {
                        totalRowsField
                    }
                    
                    notesField
                    
                    ProjectImageSelectorView(
                        imagePaths: viewModel.imagePaths,
                        imagePathForDisplay: { viewModel.resolvedImagePathForDisplay($0) },
                        onAddImage: { viewModel.addImage($0) },
                        onRemoveImage: { viewModel.removeImagePath($0) },
                        onApplyImagePathsOrder: { viewModel.applyImagePathsOrder($0) },
                        onReorderDragActiveChange: { suppressScrollForPhotoReorder = $0 },
                        onOpenPreview: { index in
                            imagePreviewStartIndex = index
                            showImagePreview = true
                        }
                    )
                    
                    if viewModel.projectType == .double,
                       showsPersistedProjectExtras,
                       let project = viewModel.project,
                       project.totalRows > 0 {
                        RowProgressView(
                            currentRowCount: project.rowCounterNumber,
                            totalRows: project.totalRows
                        )
                    }
                    
                    if showsPersistedProjectExtras {
                        markAsCompletedToggle
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(24)
            }
            .scrollDisabled(suppressScrollForPhotoReorder)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(String(localized: "project.detail.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if showsDraftChrome {
                            viewModel.attemptDismissal()
                        } else if let projectId = viewModel.project?.id, let onNavigateBack {
                            onNavigateBack(projectId)
                        } else {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: showsDraftChrome ? "xmark" : "chevron.left")
                    }
                    .accessibilityLabel(
                        showsDraftChrome
                            ? String(localized: "project.detail.closeA11y")
                            : String(localized: "project.detail.backA11y")
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showsDraftChrome {
                    Button {
                        if let newId = viewModel.createProject() {
                            onProjectCreated?(newId)
                        }
                    } label: {
                        Text(String(localized: "Create Project"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.primary)
                            .foregroundStyle(colors.onPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .accessibilityHint(
                        isFormValid
                            ? String(localized: "project.create.button.hint.enabled")
                            : String(localized: "project.create.button.hint.disabled")
                    )
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
            guard let newValue else { return }
            switch newValue {
            case .allowed:
                viewModel.dismissalResult = nil
                onDismiss()
            case .showDiscardDialog:
                showDiscardDialog = true
            case .blocked:
                break
            }
        }
        .alert(
            discardAlertTitle,
            isPresented: $showDiscardDialog
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                viewModel.dismissalResult = nil
            }
            Button(String(localized: "Discard"), role: .destructive) {
                viewModel.discardChanges()
                viewModel.dismissalResult = nil
                onDismiss()
            }
        } message: {
            Text(discardAlertMessage)
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            if !viewModel.imagePaths.isEmpty {
                ProjectImagePreviewSheet(
                    imagePaths: viewModel.imagePaths,
                    initialIndex: imagePreviewStartIndex,
                    absolutePathForLoading: viewModel.resolvedImagePathForDisplay,
                    onClose: { showImagePreview = false }
                )
            }
        }
    }
    
    private var isTitleEmptyForDiscardDialog: Bool {
        viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var discardAlertTitle: String {
        isTitleEmptyForDiscardDialog
            ? String(localized: "project.discard.title.needsTitle")
            : String(localized: "project.discard.title.hasChanges")
    }
    
    private var discardAlertMessage: String {
        isTitleEmptyForDiscardDialog
            ? String(localized: "project.discard.message.needsTitle")
            : String(localized: "project.discard.message.hasChanges")
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Project Title"))
                .font(.subheadline)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            
            TextField(String(localized: "Enter project title"), text: Binding(
                get: { viewModel.title },
                set: { viewModel.updateTitle($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: .title)
            .submitLabel(viewModel.projectType == .double ? .next : .done)
            .onSubmit {
                if viewModel.projectType == .double {
                    focusedField = .totalRows
                } else {
                    focusedField = nil
                }
            }
            
            if let error = viewModel.titleError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(colors.error)
            }
        }
    }
    
    private var totalRowsField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Total Rows"))
                .font(.subheadline)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            
            TextField(String(localized: "Enter total rows"), text: Binding(
                get: { viewModel.totalRows },
                set: { viewModel.updateTotalRows($0) }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .focused($focusedField, equals: .totalRows)
            .submitLabel(.done)
            .onSubmit { focusedField = nil }
            
            if let error = viewModel.totalRowsError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(colors.error)
            }
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Project Notes"))
                .font(.subheadline)
                .foregroundStyle(colors.onSurface.opacity(0.6))
            
            ZStack(alignment: .topLeading) {
                if viewModel.notes.isEmpty {
                    Text(String(localized: "Enter notes about your project"))
                        .foregroundStyle(colors.onSurface.opacity(0.3))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)
                }
                
                TextEditor(text: Binding(
                    get: { viewModel.notes },
                    set: { viewModel.updateNotes($0) }
                ))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(colors.onSurface.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Project Notes"))
        .accessibilityHint(String(localized: "Enter notes about your project"))
    }
    
    private var markAsCompletedToggle: some View {
        Toggle(isOn: Binding(
            get: { viewModel.isCompleted },
            set: { viewModel.toggleCompleted($0) }
        )) {
            Text(String(localized: "Finished"))
                .font(.body)
        }
        .tint(colors.primary)
        .accessibilityLabel(String(localized: "Finished"))
        .accessibilityHint(String(localized: "Toggles whether this project is finished"))
    }
    
    private var isFormValid: Bool {
        let titleValid = !viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty
        let totalRowsValid = viewModel.projectType != .double || (Int(viewModel.totalRows) ?? 0) > 0
        return titleValid && totalRowsValid
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
