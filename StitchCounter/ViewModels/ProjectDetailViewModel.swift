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
        if !newTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            titleError = nil
        }
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
        
        if projectType == .double {
            let trimmed = newTotalRows.trimmingCharacters(in: .whitespaces)
            let value = Int(trimmed) ?? 0
            if !trimmed.isEmpty && value > 0 {
                totalRowsError = nil
            }
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
    
    func reorderImagePaths(draggedPath: String, dropTargetPath: String) {
        guard draggedPath != dropTargetPath,
              let fromIndex = imagePaths.firstIndex(of: draggedPath),
              let toIndex = imagePaths.firstIndex(of: dropTargetPath) else { return }
        var paths = imagePaths
        let moved = paths.remove(at: fromIndex)
        paths.insert(moved, at: toIndex)
        imagePaths = paths
        recalculateHasUnsavedChanges()
        triggerAutoSave()
    }
    
    func applyImagePathsOrder(_ newOrder: [String]) {
        guard newOrder.count == imagePaths.count else { return }
        let oldFrequency = Dictionary(grouping: imagePaths, by: { $0 }).mapValues { $0.count }
        let newFrequency = Dictionary(grouping: newOrder, by: { $0 }).mapValues { $0.count }
        guard oldFrequency == newFrequency else { return }
        imagePaths = newOrder
        recalculateHasUnsavedChanges()
        triggerAutoSave()
    }
    
    func createProject() -> UUID? {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            titleError = String(localized: "project.validation.titleRequired")
            return nil
        }
        
        let totalRowsValue: Int
        if projectType == .double {
            let trimmedRows = totalRows.trimmingCharacters(in: .whitespaces)
            if trimmedRows.isEmpty {
                totalRowsError = String(localized: "project.validation.totalRowsRequired")
                return nil
            }
            let parsedRows = Int(trimmedRows) ?? 0
            if parsedRows <= 0 {
                totalRowsError = String(localized: "project.validation.totalRowsGreaterThanZero")
                return nil
            }
            totalRowsValue = parsedRows
        } else {
            totalRowsValue = Int(totalRows.trimmingCharacters(in: .whitespaces)) ?? 0
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
