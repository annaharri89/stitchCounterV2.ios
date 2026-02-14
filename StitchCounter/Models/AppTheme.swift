import Foundation

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case seaCottage = "sea_cottage"
    case retroSummer = "retro_summer"
    case dustyRose = "dusty_rose"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .seaCottage: return "Sea Cottage"
        case .retroSummer: return "Retro Summer"
        case .dustyRose: return "Dusty Rose"
        }
    }
}
