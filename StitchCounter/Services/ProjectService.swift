import Foundation
import SwiftData
import Combine

@MainActor
protocol ProjectServiceProtocol {
    func getProject(by id: UUID) -> Project?
    func saveProject(_ project: Project)
    func createProject(type: ProjectType) -> Project
    func saveImage(_ imageData: Data, for project: Project, at index: Int) -> String?
    func resolvedImagePathForDisplay(_ storedPath: String) -> String
}

@MainActor
final class ProjectService: ObservableObject, ProjectServiceProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @Published private(set) var projects: [Project] = []
    
    init() {
        do {
            let schema = Schema([Project.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = modelContainer.mainContext
            fetchProjects()
        } catch {
            fatalError("StitchCounter_ProjectService_InitFailed: \(error)")
        }
    }
    
    func fetchProjects() {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            projects = try modelContext.fetch(descriptor)
        } catch {
            print("StitchCounter_ProjectService_FetchFailed: \(error)")
        }
    }
    
    func getProject(by id: UUID) -> Project? {
        projects.first { $0.id == id }
    }
    
    func createProject(type: ProjectType) -> Project {
        let project = Project(type: type)
        modelContext.insert(project)
        saveContext()
        fetchProjects()
        return project
    }
    
    func saveProject(_ project: Project) {
        project.updatedAt = Date()
        saveContext()
        fetchProjects()
    }
    
    func deleteProject(_ project: Project) {
        deleteProjectImages(project)
        modelContext.delete(project)
        saveContext()
        fetchProjects()
    }
    
    func deleteProjects(_ projectsToDelete: [Project]) {
        for project in projectsToDelete {
            deleteProjectImages(project)
            modelContext.delete(project)
        }
        saveContext()
        fetchProjects()
    }
    
    private func documentsDirectoryURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func resolvedImagePathForDisplay(_ storedPath: String) -> String {
        guard let documentsDirectory = documentsDirectoryURL() else {
            return storedPath
        }
        return ProjectImagePathResolver.absolutePathForLoading(
            storedPath: storedPath,
            documentsDirectory: documentsDirectory
        )
    }

    private func deleteProjectImages(_ project: Project) {
        guard let documentsDirectory = documentsDirectoryURL() else { return }
        let fileManager = FileManager.default
        for path in project.imagePaths {
            let url = ProjectImagePathResolver.fileURL(storedPath: path, documentsDirectory: documentsDirectory)
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("StitchCounter_ProjectService_SaveFailed: \(error)")
        }
    }
    
    func saveImage(_ imageData: Data, for project: Project, at index: Int) -> String? {
        guard let documentsDirectory = documentsDirectoryURL() else {
            return nil
        }

        let projectImagesDirectory = documentsDirectory.appendingPathComponent("project_images", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: projectImagesDirectory, withIntermediateDirectories: true)
        } catch {
            print("StitchCounter_ProjectService_CreateDirectoryFailed: \(error)")
            return nil
        }

        let fileName =
            "project_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString)_\(index).jpg"
        let fileURL = projectImagesDirectory.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return "project_images/\(fileName)"
        } catch {
            print("StitchCounter_ProjectService_SaveImageFailed: \(error)")
            return nil
        }
    }

    func removeImage(at path: String, from project: Project) {
        if let documentsDirectory = documentsDirectoryURL() {
            let url = ProjectImagePathResolver.fileURL(storedPath: path, documentsDirectory: documentsDirectory)
            try? FileManager.default.removeItem(at: url)
        }
        project.imagePaths.removeAll { $0 == path }
        saveProject(project)
    }
    
    // MARK: - Export / Import

    func exportLibrary() throws -> URL {
        guard let documentsDirectory = documentsDirectoryURL() else {
            throw LibraryBackupError.documentsDirectoryUnavailable
        }
        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "1.0"
        return try LibraryBackupManager.exportZip(
            projects: projects,
            documentsDirectory: documentsDirectory,
            appVersion: appVersion
        )
    }

    func importLibrary(from url: URL) throws -> LibraryImportResult {
        guard let documentsDirectory = documentsDirectoryURL() else {
            throw LibraryBackupError.documentsDirectoryUnavailable
        }

        let fileManager = FileManager.default
        let fileData = try Data(contentsOf: url)
        let treatAsZip = LibraryBackupManager.shouldTreatAsZipImport(
            fileData: fileData,
            pathExtension: url.pathExtension
        )
        guard treatAsZip else {
            throw LibraryBackupError.notZipFile
        }

        let tempZip = fileManager.temporaryDirectory.appendingPathComponent("stitch_import_\(UUID().uuidString).zip")
        try fileData.write(to: tempZip)
        defer {
            try? fileManager.removeItem(at: tempZip)
        }
        let result = try LibraryBackupManager.importFromZip(
            zipURL: tempZip,
            documentsDirectory: documentsDirectory
        ) { project in
            modelContext.insert(project)
        }
        saveContext()
        fetchProjects()
        return result
    }
}
