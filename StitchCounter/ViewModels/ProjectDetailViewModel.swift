import SwiftUI
import Combine
import PhotosUI

enum DismissalResult {
    case allowed
    case blocked
    case showDiscardDialog
}

@MainActor
final class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project?
    @Published var title: String = ""
    @Published var projectType: ProjectType = .single
    @Published var totalRows: String = ""
    @Published var imagePaths: [String] = []
    @Published var isLoading: Bool = false
    @Published var hasUnsavedChanges: Bool = false
    @Published var titleError: String?
    @Published var totalRowsError: String?
    @Published var dismissalResult: DismissalResult?
    
    private let projectService: ProjectService
    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveDelayNanoseconds: UInt64 = 1_000_000_000
    private var originalTitle: String = ""
    private var originalTotalRows: String = ""
    private var originalImagePaths: [String] = []
    
    init(projectService: ProjectService) {
        self.projectService = projectService
    }
    
    func loadProject(_ projectId: UUID?, projectType: ProjectType) {
        isLoading = true
        
        if let projectId = projectId, let existingProject = projectService.getProject(by: projectId) {
            project = existingProject
            title = existingProject.title
            self.projectType = existingProject.type
            totalRows = existingProject.totalRows > 0 ? String(existingProject.totalRows) : ""
            imagePaths = existingProject.imagePaths
            originalTitle = existingProject.title
            originalTotalRows = totalRows
            originalImagePaths = existingProject.imagePaths
        } else {
            let newProject = Project(type: projectType)
            project = newProject
            title = ""
            self.projectType = projectType
            totalRows = ""
            imagePaths = []
            originalTitle = ""
            originalTotalRows = ""
            originalImagePaths = []
        }
        
        isLoading = false
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
    }
    
    func loadProjectById(_ projectId: UUID) {
        isLoading = true
        
        guard let existingProject = projectService.getProject(by: projectId) else {
            isLoading = false
            return
        }
        
        project = existingProject
        title = existingProject.title
        projectType = existingProject.type
        totalRows = existingProject.totalRows > 0 ? String(existingProject.totalRows) : ""
        imagePaths = existingProject.imagePaths
        originalTitle = existingProject.title
        originalTotalRows = totalRows
        originalImagePaths = existingProject.imagePaths
        
        isLoading = false
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
        hasUnsavedChanges = newTitle != originalTitle || totalRows != originalTotalRows || imagePaths != originalImagePaths
        titleError = newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? "Title is required" : nil
        triggerAutoSave()
    }
    
    func updateTotalRows(_ newTotalRows: String) {
        totalRows = newTotalRows
        hasUnsavedChanges = title != originalTitle || newTotalRows != originalTotalRows || imagePaths != originalImagePaths
        
        let totalRowsValue = Int(newTotalRows) ?? 0
        let isDoubleCounter = projectType == .double
        
        if isDoubleCounter && totalRowsValue <= 0 && !newTotalRows.isEmpty {
            totalRowsError = "Total rows must be greater than 0"
        } else if isDoubleCounter && newTotalRows.isEmpty {
            totalRowsError = "Total rows is required"
        } else {
            totalRowsError = nil
        }
        
        triggerAutoSave()
    }
    
    private func triggerAutoSave() {
        autoSaveTask?.cancel()
        guard let project = project, project.id != UUID() else { return }
        let isExistingProject = projectService.getProject(by: project.id) != nil
        
        guard hasUnsavedChanges && isExistingProject else { return }
        
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: autoSaveDelayNanoseconds)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    
    func save() {
        guard let existingProject = project else { return }
        
        existingProject.title = title
        existingProject.totalRows = Int(totalRows) ?? 0
        existingProject.imagePaths = imagePaths
        projectService.saveProject(existingProject)
        
        originalTitle = title
        originalTotalRows = totalRows
        originalImagePaths = imagePaths
        hasUnsavedChanges = false
    }
    
    func attemptDismissal() {
        autoSaveTask?.cancel()
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            titleError = "Title is required"
            dismissalResult = .showDiscardDialog
        } else if hasUnsavedChanges {
            dismissalResult = .showDiscardDialog
        } else {
            save()
            dismissalResult = .allowed
        }
    }
    
    func discardChanges() {
        title = originalTitle
        totalRows = originalTotalRows
        imagePaths = originalImagePaths
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
    }
    
    func addImage(_ imageData: Data) {
        guard let project = project else { return }
        
        let index = imagePaths.count
        if let savedPath = projectService.saveImage(imageData, for: project, at: index) {
            imagePaths.append(savedPath)
            hasUnsavedChanges = true
            triggerAutoSave()
        }
    }
    
    func removeImagePath(_ imagePath: String) {
        imagePaths.removeAll { $0 == imagePath }
        hasUnsavedChanges = true
        triggerAutoSave()
    }
    
    func createProject() -> UUID? {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            titleError = "Title is required"
            return nil
        }
        
        let isDoubleCounter = projectType == .double
        let totalRowsValue = Int(totalRows) ?? 0
        
        if isDoubleCounter && totalRowsValue <= 0 {
            totalRowsError = "Total rows is required and must be greater than 0"
            return nil
        }
        
        let newProject = projectService.createProject(type: projectType)
        newProject.title = title
        newProject.totalRows = totalRowsValue
        newProject.imagePaths = imagePaths
        projectService.saveProject(newProject)
        
        project = newProject
        originalTitle = title
        originalTotalRows = totalRows
        originalImagePaths = imagePaths
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
        
        return newProject.id
    }
}
