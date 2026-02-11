import Foundation

enum CounterType: String, CaseIterable {
    case stitch
    case row
    
    var displayName: String {
        switch self {
        case .stitch: return "Stitches"
        case .row: return "Rows/Rounds"
        }
    }
}
