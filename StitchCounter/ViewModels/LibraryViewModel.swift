import SwiftUI
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var isMultiSelectMode: Bool = false
    @Published var selectedProjectIds: Set<UUID> = []
    @Published var showDeleteConfirmation: Bool = false
    @Published var projectsToDelete: [Project] = []
    @Published var isLoading: Bool = true
    
    let projectService: ProjectService
    
    var projects: [Project] {
        projectService.projects
    }
    
    init(projectService: ProjectService) {
        self.projectService = projectService
        isLoading = false
    }
    
    func toggleMultiSelectMode() {
        isMultiSelectMode.toggle()
        if !isMultiSelectMode {
            selectedProjectIds.removeAll()
        }
    }
    
    func toggleProjectSelection(_ projectId: UUID) {
        if selectedProjectIds.contains(projectId) {
            selectedProjectIds.remove(projectId)
        } else {
            selectedProjectIds.insert(projectId)
        }
    }
    
    func selectAllProjects() {
        selectedProjectIds = Set(projects.map { $0.id })
    }
    
    func clearSelection() {
        selectedProjectIds.removeAll()
    }
    
    func requestDelete(_ project: Project) {
        projectsToDelete = [project]
        showDeleteConfirmation = true
    }
    
    func requestBulkDelete() {
        let toDelete = projects.filter { selectedProjectIds.contains($0.id) }
        if !toDelete.isEmpty {
            projectsToDelete = toDelete
            showDeleteConfirmation = true
        }
    }
    
    func confirmDelete() {
        if projectsToDelete.count == 1 {
            projectService.deleteProject(projectsToDelete[0])
        } else {
            projectService.deleteProjects(projectsToDelete)
        }
        showDeleteConfirmation = false
        projectsToDelete = []
        selectedProjectIds.removeAll()
        isMultiSelectMode = false
    }
    
    func cancelDelete() {
        showDeleteConfirmation = false
        projectsToDelete = []
    }
    
    func refreshProjects() {
        projectService.fetchProjects()
    }
}
