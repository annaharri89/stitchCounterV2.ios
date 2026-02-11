import Foundation
import SwiftData
import Combine

@MainActor
final class ProjectService: ObservableObject {
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
    
    private func deleteProjectImages(_ project: Project) {
        let fileManager = FileManager.default
        for path in project.imagePaths {
            try? fileManager.removeItem(atPath: path)
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
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let projectImagesDirectory = documentsDirectory.appendingPathComponent("ProjectImages/\(project.id.uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: projectImagesDirectory, withIntermediateDirectories: true)
        } catch {
            print("StitchCounter_ProjectService_CreateDirectoryFailed: \(error)")
            return nil
        }
        
        let fileName = "image_\(index)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = projectImagesDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("StitchCounter_ProjectService_SaveImageFailed: \(error)")
            return nil
        }
    }
    
    func removeImage(at path: String, from project: Project) {
        try? FileManager.default.removeItem(atPath: path)
        project.imagePaths.removeAll { $0 == path }
        saveProject(project)
    }
}
