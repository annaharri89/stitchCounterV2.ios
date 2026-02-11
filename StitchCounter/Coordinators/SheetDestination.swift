import Foundation

enum SheetDestination: Identifiable, Equatable {
    case singleCounter(projectId: UUID)
    case doubleCounter(projectId: UUID)
    case newProjectDetail(projectType: ProjectType)
    case projectDetail(projectId: UUID)
    
    var id: String {
        switch self {
        case .singleCounter(let projectId):
            return "single_\(projectId.uuidString)"
        case .doubleCounter(let projectId):
            return "double_\(projectId.uuidString)"
        case .newProjectDetail(let projectType):
            return "new_detail_\(projectType.rawValue)"
        case .projectDetail(let projectId):
            return "detail_\(projectId.uuidString)"
        }
    }
}
