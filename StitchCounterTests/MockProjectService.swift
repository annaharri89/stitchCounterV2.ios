import Foundation
@testable import StitchCounter

@MainActor
final class MockProjectService: ProjectServiceProtocol {
    var projectsByID: [UUID: Project] = [:]
    private(set) var savedProjects: [Project] = []
    
    func getProject(by id: UUID) -> Project? {
        projectsByID[id]
    }
    
    func saveProject(_ project: Project) {
        savedProjects.append(project)
        projectsByID[project.id] = project
    }
    
    func createProject(type: ProjectType) -> Project {
        let project = Project(type: type)
        projectsByID[project.id] = project
        return project
    }
    
    func saveImage(_ imageData: Data, for project: Project, at index: Int) -> String? {
        "project_images/mock_\(project.id.uuidString.prefix(8))_\(index).jpg"
    }
    
    func resolvedImagePathForDisplay(_ storedPath: String) -> String {
        storedPath
    }
    
    func addProject(_ project: Project) {
        projectsByID[project.id] = project
    }
}
