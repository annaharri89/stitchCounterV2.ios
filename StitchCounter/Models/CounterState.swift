import Foundation

struct CounterState: Equatable {
    var count: Int = 0
    var adjustment: AdjustmentAmount = .one
    var customAdjustmentAmount: Int = AdjustmentAmount.custom.defaultAmount
    
    var resolvedAdjustmentAmount: Int {
        if adjustment == .custom {
            return max(customAdjustmentAmount, 1)
        }
        return adjustment.defaultAmount
    }
    
    func incremented() -> CounterState {
        CounterState(
            count: count + resolvedAdjustmentAmount,
            adjustment: adjustment,
            customAdjustmentAmount: customAdjustmentAmount
        )
    }
    
    func decremented() -> CounterState {
        CounterState(
            count: max(0, count - resolvedAdjustmentAmount),
            adjustment: adjustment,
            customAdjustmentAmount: customAdjustmentAmount
        )
    }
    
    func reset() -> CounterState {
        CounterState(
            count: 0,
            adjustment: adjustment,
            customAdjustmentAmount: customAdjustmentAmount
        )
    }
    
    func withAdjustment(_ newAdjustment: AdjustmentAmount) -> CounterState {
        CounterState(
            count: count,
            adjustment: newAdjustment,
            customAdjustmentAmount: customAdjustmentAmount
        )
    }
    
    func withCustomAdjustmentAmount(_ amount: Int) -> CounterState {
        CounterState(
            count: count,
            adjustment: .custom,
            customAdjustmentAmount: max(amount, 1)
        )
    }
}
