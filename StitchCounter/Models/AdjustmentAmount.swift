import Foundation

enum AdjustmentAmount: Int, CaseIterable, Identifiable {
    case one = 1
    case five = 5
    case ten = 10
    
    var id: Int { rawValue }
    
    var amount: Int { rawValue }
    
    var displayText: String {
        "+\(rawValue)"
    }
}
