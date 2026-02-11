import SwiftUI

struct LibraryScreen: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Binding var showingSheet: SheetDestination?
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingState
                } else if viewModel.projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Library")
            .toolbar {
                if viewModel.isMultiSelectMode {
                    multiSelectToolbar
                } else {
                    normalToolbar
                }
            }
        }
        .deleteConfirmationDialog(
            isPresented: $viewModel.showDeleteConfirmation,
            projectCount: viewModel.projectsToDelete.count,
            onConfirm: { viewModel.confirmDelete() },
            onCancel: { viewModel.cancelDelete() }
        )
        .onAppear {
            viewModel.refreshProjects()
        }
    }
    
    private var loadingState: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(colors.onSurface.opacity(0.4))
            
            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first project to start tracking your stitches")
                .font(.body)
                .foregroundColor(colors.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var projectList: some View {
        List {
            ForEach(viewModel.projects, id: \.id) { project in
                ProjectRowView(
                    project: project,
                    isSelected: viewModel.selectedProjectIds.contains(project.id),
                    isMultiSelectMode: viewModel.isMultiSelectMode,
                    onTap: {
                        if viewModel.isMultiSelectMode {
                            viewModel.toggleProjectSelection(project.id)
                        } else {
                            openProject(project)
                        }
                    },
                    onLongPress: {
                        if !viewModel.isMultiSelectMode {
                            viewModel.toggleMultiSelectMode()
                            viewModel.toggleProjectSelection(project.id)
                        }
                    },
                    onInfoTap: {
                        showingSheet = .projectDetail(projectId: project.id)
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !viewModel.isMultiSelectMode {
                        Button(role: .destructive) {
                            viewModel.requestDelete(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
    
    private func openProject(_ project: Project) {
        switch project.type {
        case .single:
            showingSheet = .singleCounter(projectId: project.id)
        case .double:
            showingSheet = .doubleCounter(projectId: project.id)
        }
    }
    
    @ToolbarContentBuilder
    private var normalToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !viewModel.projects.isEmpty {
                Button {
                    viewModel.toggleMultiSelectMode()
                } label: {
                    Image(systemName: "checklist")
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var multiSelectToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.toggleMultiSelectMode()
            } label: {
                Image(systemName: "xmark")
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text(viewModel.selectedProjectIds.isEmpty ? "Select projects" : "\(viewModel.selectedProjectIds.count) selected")
                .font(.headline)
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            if viewModel.selectedProjectIds.count == viewModel.projects.count && !viewModel.projects.isEmpty {
                Button {
                    viewModel.clearSelection()
                } label: {
                    Image(systemName: "checkmark.circle")
                }
            } else {
                Button {
                    viewModel.selectAllProjects()
                } label: {
                    Image(systemName: "checklist.checked")
                }
            }
            
            Button {
                viewModel.requestBulkDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(viewModel.selectedProjectIds.isEmpty ? colors.onSurface.opacity(0.4) : colors.error)
            }
            .disabled(viewModel.selectedProjectIds.isEmpty)
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onInfoTap: () -> Void
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        HStack(spacing: 16) {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface.opacity(0.4))
            } else {
                projectImage
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title.isEmpty ? "Untitled Project" : project.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(project.type == .single ? "Single" : "Double", systemImage: project.type == .single ? "number.circle" : "number.circle.fill")
                        .font(.caption)
                        .foregroundColor(colors.onSurface.opacity(0.6))
                    
                    if project.type == .double && project.totalRows > 0 {
                        Text("\(project.rowCounterNumber)/\(project.totalRows) rows")
                            .font(.caption)
                            .foregroundColor(colors.onSurface.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            if !isMultiSelectMode {
                Button {
                    onInfoTap()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected && isMultiSelectMode ? colors.primaryContainer : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    @ViewBuilder
    private var projectImage: some View {
        if let firstImagePath = project.imagePaths.first,
           let uiImage = UIImage(contentsOfFile: firstImagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .clipped()
        } else {
            Image(systemName: project.type == .single ? "number.circle" : "number.circle.fill")
                .font(.title)
                .frame(width: 50, height: 50)
                .background(colors.primaryContainer)
                .cornerRadius(8)
                .foregroundColor(colors.primary)
        }
    }
}

#Preview {
    LibraryScreen(
        viewModel: LibraryViewModel(projectService: ProjectService()),
        showingSheet: .constant(nil)
    )
}
