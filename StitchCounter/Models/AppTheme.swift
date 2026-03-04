import Foundation

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case seaCottage = "sea_cottage"
    case dustyRose = "dusty_rose"
    case goldenHearth = "golden_hearth"
    case forestFiber = "forest_fiber"
    case cloudSoft = "cloud_soft"
    case yarnCandy = "yarn_candy"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .seaCottage: return "Sea Cottage"
        case .dustyRose: return "Dusty Rose"
        case .goldenHearth: return "Golden Hearth"
        case .forestFiber: return "Forest Fiber"
        case .cloudSoft: return "Cloud Soft"
        case .yarnCandy: return "Yarn Candy"
        }
    }
}
