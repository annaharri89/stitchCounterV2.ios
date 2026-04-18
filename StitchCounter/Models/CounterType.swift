import Foundation

enum CounterType: String, CaseIterable {
    case stitch
    case row
    
    var displayName: String {
        switch self {
        case .stitch:
            return String(localized: String.LocalizationValue("counter.type.stitches"))
        case .row:
            return String(localized: String.LocalizationValue("counter.type.rowsRounds"))
        }
    }
}
