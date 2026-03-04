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
    
    func addProject(_ project: Project) {
        projectsByID[project.id] = project
    }
}
