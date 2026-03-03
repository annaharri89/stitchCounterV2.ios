import XCTest
@testable import StitchCounter

final class CounterStateTests: XCTestCase {
    
    func testDefaultStateHasZeroCountAndAdjustmentOne() {
        let state = CounterState()
        XCTAssertEqual(state.count, 0)
        XCTAssertEqual(state.adjustment, .one)
        XCTAssertEqual(state.customAdjustmentAmount, AdjustmentAmount.custom.defaultAmount)
    }
    
    // MARK: - resolvedAdjustmentAmount
    
    func testResolvedAdjustmentAmountReturnsOneDefaultWhenAdjustmentIsOne() {
        let state = CounterState(adjustment: .one)
        XCTAssertEqual(state.resolvedAdjustmentAmount, 1)
    }
    
    func testResolvedAdjustmentAmountReturnsFiveDefaultWhenAdjustmentIsFive() {
        let state = CounterState(adjustment: .five)
        XCTAssertEqual(state.resolvedAdjustmentAmount, 5)
    }
    
    func testResolvedAdjustmentAmountReturnsCustomAmountWhenAdjustmentIsCustom() {
        let state = CounterState(adjustment: .custom, customAdjustmentAmount: 7)
        XCTAssertEqual(state.resolvedAdjustmentAmount, 7)
    }
    
    func testResolvedAdjustmentAmountCoercesCustomZeroToOne() {
        let state = CounterState(adjustment: .custom, customAdjustmentAmount: 0)
        XCTAssertEqual(state.resolvedAdjustmentAmount, 1)
    }
    
    func testResolvedAdjustmentAmountCoercesCustomNegativeToOne() {
        let state = CounterState(adjustment: .custom, customAdjustmentAmount: -5)
        XCTAssertEqual(state.resolvedAdjustmentAmount, 1)
    }
    
    // MARK: - incremented
    
    func testIncrementedAddsResolvedAmountToCount() {
        let state = CounterState(count: 10, adjustment: .one)
        XCTAssertEqual(state.incremented().count, 11)
    }
    
    func testIncrementedByFiveAddsFive() {
        let state = CounterState(count: 3, adjustment: .five)
        XCTAssertEqual(state.incremented().count, 8)
    }
    
    func testIncrementedByCustomUsesCustomAdjustmentAmount() {
        let state = CounterState(count: 0, adjustment: .custom, customAdjustmentAmount: 12)
        XCTAssertEqual(state.incremented().count, 12)
    }
    
    func testIncrementedPreservesAdjustmentAndCustomAmount() {
        let state = CounterState(count: 5, adjustment: .custom, customAdjustmentAmount: 3)
        let incremented = state.incremented()
        XCTAssertEqual(incremented.adjustment, .custom)
        XCTAssertEqual(incremented.customAdjustmentAmount, 3)
    }
    
    // MARK: - decremented
    
    func testDecrementedSubtractsResolvedAmountFromCount() {
        let state = CounterState(count: 10, adjustment: .one)
        XCTAssertEqual(state.decremented().count, 9)
    }
    
    func testDecrementedFloorsAtZero() {
        let state = CounterState(count: 2, adjustment: .five)
        XCTAssertEqual(state.decremented().count, 0)
    }
    
    func testDecrementedFromZeroStaysAtZero() {
        let state = CounterState(count: 0, adjustment: .one)
        XCTAssertEqual(state.decremented().count, 0)
    }
    
    // MARK: - reset
    
    func testResetSetsCountToZeroAndPreservesAdjustment() {
        let state = CounterState(count: 42, adjustment: .five, customAdjustmentAmount: 8)
        let resetState = state.reset()
        XCTAssertEqual(resetState.count, 0)
        XCTAssertEqual(resetState.adjustment, .five)
        XCTAssertEqual(resetState.customAdjustmentAmount, 8)
    }
    
    // MARK: - withAdjustment
    
    func testWithAdjustmentChangesEnumAndPreservesCustomAmount() {
        let state = CounterState(count: 5, adjustment: .one, customAdjustmentAmount: 7)
        let updated = state.withAdjustment(.five)
        XCTAssertEqual(updated.adjustment, .five)
        XCTAssertEqual(updated.customAdjustmentAmount, 7)
        XCTAssertEqual(updated.count, 5)
    }
    
    // MARK: - withCustomAdjustmentAmount
    
    func testWithCustomAdjustmentAmountSetsCustomAndCoerces() {
        let state = CounterState(count: 5, adjustment: .one)
        let updated = state.withCustomAdjustmentAmount(15)
        XCTAssertEqual(updated.adjustment, .custom)
        XCTAssertEqual(updated.customAdjustmentAmount, 15)
        XCTAssertEqual(updated.count, 5)
    }
    
    func testWithCustomAdjustmentAmountCoercesZeroToOne() {
        let state = CounterState()
        let updated = state.withCustomAdjustmentAmount(0)
        XCTAssertEqual(updated.customAdjustmentAmount, 1)
    }
    
    func testWithCustomAdjustmentAmountCoercesNegativeToOne() {
        let state = CounterState()
        let updated = state.withCustomAdjustmentAmount(-10)
        XCTAssertEqual(updated.customAdjustmentAmount, 1)
    }
}
