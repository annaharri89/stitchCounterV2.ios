import Foundation
import SwiftData
import Combine

@MainActor
protocol ProjectServiceProtocol {
    func getProject(by id: UUID) -> Project?
    func saveProject(_ project: Project)
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
    
    // MARK: - Export / Import
    
    func exportLibrary() throws -> URL {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ProjectServiceError.documentsDirectoryUnavailable
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let exportFileName = "stitch_counter_backup_\(timestamp).json"
        let exportURL = documentsDirectory.appendingPathComponent(exportFileName)
        
        let dateFormatter = ISO8601DateFormatter()
        let exportData = projects.map { project in
            var dict: [String: Any] = [
                "id": project.id.uuidString,
                "type": project.type.rawValue,
                "title": project.title,
                "notes": project.notes,
                "stitchCounterNumber": project.stitchCounterNumber,
                "stitchAdjustment": project.stitchAdjustment,
                "rowCounterNumber": project.rowCounterNumber,
                "rowAdjustment": project.rowAdjustment,
                "totalRows": project.totalRows,
                "imagePaths": project.imagePaths,
                "createdAt": dateFormatter.string(from: project.createdAt),
                "updatedAt": dateFormatter.string(from: project.updatedAt),
                "totalStitchesEver": project.totalStitchesEver
            ]
            if let completedAt = project.completedAt {
                dict["completedAt"] = dateFormatter.string(from: completedAt)
            }
            return dict
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: exportURL)
        return exportURL
    }
    
    func importLibrary(from url: URL) throws -> (importedCount: Int, failedCount: Int) {
        let data = try Data(contentsOf: url)
        guard let projectsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ProjectServiceError.invalidBackupFormat
        }
        
        var importedCount = 0
        var failedCount = 0
        let dateFormatter = ISO8601DateFormatter()
        
        for projectDict in projectsArray {
            guard let typeString = projectDict["type"] as? String,
                  let type = ProjectType(rawValue: typeString),
                  let title = projectDict["title"] as? String else {
                failedCount += 1
                continue
            }
            
            let newProject = createProject(type: type)
            newProject.title = title
            newProject.notes = projectDict["notes"] as? String ?? ""
            newProject.stitchCounterNumber = projectDict["stitchCounterNumber"] as? Int ?? 0
            newProject.stitchAdjustment = projectDict["stitchAdjustment"] as? Int ?? 1
            newProject.rowCounterNumber = projectDict["rowCounterNumber"] as? Int ?? 0
            newProject.rowAdjustment = projectDict["rowAdjustment"] as? Int ?? 1
            newProject.totalRows = projectDict["totalRows"] as? Int ?? 0
            newProject.totalStitchesEver = projectDict["totalStitchesEver"] as? Int ?? 0
            if let completedAtString = projectDict["completedAt"] as? String {
                newProject.completedAt = dateFormatter.date(from: completedAtString)
            }
            
            saveProject(newProject)
            importedCount += 1
        }
        
        return (importedCount, failedCount)
    }
}

enum ProjectServiceError: LocalizedError {
    case documentsDirectoryUnavailable
    case invalidBackupFormat
    
    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            String(localized: "Could not access documents directory")
        case .invalidBackupFormat:
            String(localized: "Invalid backup format")
        }
    }
}
