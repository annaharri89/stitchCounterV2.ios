import Foundation

enum AdjustmentAmount: Int, CaseIterable, Identifiable {
    case one = 1
    case five = 5
    case custom = 10
    
    var id: Int { rawValue }
    
    var defaultAmount: Int { rawValue }
    
    var displayText: String {
        switch self {
        case .one: "+1"
        case .five: "+5"
        case .custom: "+\(rawValue)"
        }
    }
    
    func displayText(customAmount: Int) -> String {
        switch self {
        case .custom: "+\(customAmount)"
        default: displayText
        }
    }
    
    static func fromPersistedAmount(
        _ amount: Int,
        previousCustomAdjustmentAmount: Int = AdjustmentAmount.custom.defaultAmount
    ) -> (adjustment: AdjustmentAmount, customAdjustmentAmount: Int) {
        switch amount {
        case AdjustmentAmount.one.defaultAmount:
            return (.one, previousCustomAdjustmentAmount)
        case AdjustmentAmount.five.defaultAmount:
            return (.five, previousCustomAdjustmentAmount)
        default:
            return (.custom, max(amount, 1))
        }
    }
}
