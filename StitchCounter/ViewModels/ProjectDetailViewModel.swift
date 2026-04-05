import SwiftUI
import Combine

enum DismissalResult: Equatable {
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
    @Published var notes: String = ""
    @Published var isCompleted: Bool = false
    @Published var completedAt: Date?
    @Published var imagePaths: [String] = []
    @Published var isLoading: Bool = false
    @Published var hasUnsavedChanges: Bool = false
    @Published var titleError: String?
    @Published var totalRowsError: String?
    @Published var dismissalResult: DismissalResult?
    
    private let projectService: ProjectServiceProtocol
    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveDelayNanoseconds: UInt64 = 1_000_000_000
    private var originalTitle: String = ""
    private var originalTotalRows: String = ""
    private var originalNotes: String = ""
    private var originalIsCompleted: Bool = false
    private var originalCompletedAt: Date?
    private var originalImagePaths: [String] = []
    
    init(projectService: ProjectServiceProtocol) {
        self.projectService = projectService
    }
    
    var isProjectPersistedInLibrary: Bool {
        guard let project else { return false }
        return projectService.getProject(by: project.id) != nil
    }
    
    func resolvedImagePathForDisplay(_ storedPath: String) -> String {
        projectService.resolvedImagePathForDisplay(storedPath)
    }
    
    func loadProject(_ projectId: UUID?, projectType: ProjectType) {
        isLoading = true
        
        if let projectId = projectId, let existingProject = projectService.getProject(by: projectId) {
            project = existingProject
            title = existingProject.title
            self.projectType = existingProject.type
            totalRows = existingProject.totalRows > 0 ? String(existingProject.totalRows) : ""
            notes = existingProject.notes
            isCompleted = existingProject.completedAt != nil
            completedAt = existingProject.completedAt
            imagePaths = existingProject.imagePaths
            originalTitle = existingProject.title
            originalTotalRows = totalRows
            originalNotes = existingProject.notes
            originalIsCompleted = isCompleted
            originalCompletedAt = existingProject.completedAt
            originalImagePaths = existingProject.imagePaths
        } else {
            let newProject = Project(type: projectType)
            project = newProject
            title = ""
            self.projectType = projectType
            totalRows = ""
            notes = ""
            isCompleted = false
            completedAt = nil
            imagePaths = []
            originalTitle = ""
            originalTotalRows = ""
            originalNotes = ""
            originalIsCompleted = false
            originalCompletedAt = nil
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
        notes = existingProject.notes
        isCompleted = existingProject.completedAt != nil
        completedAt = existingProject.completedAt
        imagePaths = existingProject.imagePaths
        originalTitle = existingProject.title
        originalTotalRows = totalRows
        originalNotes = existingProject.notes
        originalIsCompleted = isCompleted
        originalCompletedAt = existingProject.completedAt
        originalImagePaths = existingProject.imagePaths
        
        isLoading = false
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
        recalculateHasUnsavedChanges()
        titleError = newTitle.trimmingCharacters(in: .whitespaces).isEmpty
            ? String(localized: "project.validation.titleRequired")
            : nil
        triggerAutoSave()
    }
    
    func updateNotes(_ newNotes: String) {
        notes = newNotes
        recalculateHasUnsavedChanges()
        triggerAutoSave()
    }
    
    func toggleCompleted(_ isCompleted: Bool) {
        self.isCompleted = isCompleted
        completedAt = isCompleted ? (completedAt ?? Date()) : nil
        recalculateHasUnsavedChanges()
        triggerAutoSave()
    }
    
    func updateTotalRows(_ newTotalRows: String) {
        totalRows = newTotalRows
        recalculateHasUnsavedChanges()
        
        let totalRowsValue = Int(newTotalRows) ?? 0
        let isDoubleCounter = projectType == .double
        
        if isDoubleCounter && totalRowsValue <= 0 && !newTotalRows.isEmpty {
            totalRowsError = String(localized: "project.validation.totalRowsGreaterThanZero")
        } else if isDoubleCounter && newTotalRows.isEmpty {
            totalRowsError = String(localized: "project.validation.totalRowsRequired")
        } else {
            totalRowsError = nil
        }
        
        triggerAutoSave()
    }
    
    private func recalculateHasUnsavedChanges() {
        hasUnsavedChanges = title != originalTitle
            || totalRows != originalTotalRows
            || notes != originalNotes
            || isCompleted != originalIsCompleted
            || imagePaths != originalImagePaths
    }
    
    private func canPersistCurrentEdits() -> Bool {
        let titleTrimmed = title.trimmingCharacters(in: .whitespaces)
        guard !titleTrimmed.isEmpty else { return false }
        if projectType == .double {
            let trimmedRows = totalRows.trimmingCharacters(in: .whitespaces)
            guard !trimmedRows.isEmpty, (Int(trimmedRows) ?? 0) > 0 else { return false }
        }
        return true
    }
    
    private func triggerAutoSave() {
        autoSaveTask?.cancel()
        guard project != nil else { return }
        guard isProjectPersistedInLibrary else { return }
        guard hasUnsavedChanges && canPersistCurrentEdits() else { return }
        
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: autoSaveDelayNanoseconds)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    
    @discardableResult
    func save() -> Bool {
        guard let existingProject = project else { return false }
        guard canPersistCurrentEdits() else { return false }
        
        existingProject.title = title
        existingProject.totalRows = Int(totalRows) ?? 0
        existingProject.notes = notes
        existingProject.completedAt = completedAt
        existingProject.imagePaths = imagePaths
        projectService.saveProject(existingProject)
        
        originalTitle = title
        originalTotalRows = totalRows
        originalNotes = notes
        originalIsCompleted = isCompleted
        originalCompletedAt = completedAt
        originalImagePaths = imagePaths
        hasUnsavedChanges = false
        return true
    }
    
    func attemptDismissal() {
        autoSaveTask?.cancel()
        
        let titleTrimmed = title.trimmingCharacters(in: .whitespaces)
        if titleTrimmed.isEmpty {
            titleError = String(localized: "project.validation.titleRequired")
            dismissalResult = .showDiscardDialog
            return
        }
        
        if projectType == .double {
            let rowsTrimmed = totalRows.trimmingCharacters(in: .whitespaces)
            let totalRowsValue = Int(rowsTrimmed) ?? 0
            if rowsTrimmed.isEmpty {
                totalRowsError = String(localized: "project.validation.totalRowsRequired")
                dismissalResult = .showDiscardDialog
                return
            }
            if totalRowsValue <= 0 {
                totalRowsError = String(localized: "project.validation.totalRowsGreaterThanZero")
                dismissalResult = .showDiscardDialog
                return
            }
        }
        
        if isProjectPersistedInLibrary {
            if save() {
                dismissalResult = .allowed
            } else {
                dismissalResult = .showDiscardDialog
            }
        } else if createProject() != nil {
            dismissalResult = .allowed
        } else {
            dismissalResult = .showDiscardDialog
        }
    }
    
    func discardChanges() {
        title = originalTitle
        totalRows = originalTotalRows
        notes = originalNotes
        isCompleted = originalIsCompleted
        completedAt = originalCompletedAt
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
            titleError = String(localized: "project.validation.titleRequired")
            return nil
        }
        
        let isDoubleCounter = projectType == .double
        let totalRowsValue = Int(totalRows) ?? 0
        
        if isDoubleCounter && totalRowsValue <= 0 {
            totalRowsError = String(localized: "project.validation.totalRowsRequiredAndGreater")
            return nil
        }
        
        let newProject = projectService.createProject(type: projectType)
        newProject.title = title
        newProject.totalRows = totalRowsValue
        newProject.notes = notes
        newProject.completedAt = completedAt
        newProject.imagePaths = imagePaths
        projectService.saveProject(newProject)
        
        project = newProject
        originalTitle = title
        originalTotalRows = totalRows
        originalNotes = notes
        originalIsCompleted = isCompleted
        originalCompletedAt = completedAt
        originalImagePaths = imagePaths
        hasUnsavedChanges = false
        titleError = nil
        totalRowsError = nil
        
        return newProject.id
    }
}
