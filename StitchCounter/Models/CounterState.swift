import Foundation

struct CounterState: Equatable {
    var count: Int = 0
    var adjustment: AdjustmentAmount = .one
    
    func incremented() -> CounterState {
        CounterState(
            count: count + adjustment.amount,
            adjustment: adjustment
        )
    }
    
    func decremented() -> CounterState {
        CounterState(
            count: max(0, count - adjustment.amount),
            adjustment: adjustment
        )
    }
    
    func reset() -> CounterState {
        CounterState(count: 0, adjustment: adjustment)
    }
    
    func withAdjustment(_ newAdjustment: AdjustmentAmount) -> CounterState {
        CounterState(count: count, adjustment: newAdjustment)
    }
}
