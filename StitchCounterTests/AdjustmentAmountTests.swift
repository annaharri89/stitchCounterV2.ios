import XCTest
@testable import StitchCounter

final class AdjustmentAmountTests: XCTestCase {
    
    func testDefaultAmountsAreCorrect() {
        XCTAssertEqual(AdjustmentAmount.one.defaultAmount, 1)
        XCTAssertEqual(AdjustmentAmount.five.defaultAmount, 5)
        XCTAssertEqual(AdjustmentAmount.custom.defaultAmount, 10)
    }
    
    func testFromPersistedAmountMapsOneAndPreservesPreviousCustom() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(1, previousCustomAdjustmentAmount: 42)
        XCTAssertEqual(adjustment, .one)
        XCTAssertEqual(customAmount, 42)
    }
    
    func testFromPersistedAmountMapsFiveAndPreservesPreviousCustom() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(5, previousCustomAdjustmentAmount: 99)
        XCTAssertEqual(adjustment, .five)
        XCTAssertEqual(customAmount, 99)
    }
    
    func testFromPersistedAmountMapsNonStandardToCustomWithThatAmount() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(7, previousCustomAdjustmentAmount: 10)
        XCTAssertEqual(adjustment, .custom)
        XCTAssertEqual(customAmount, 7)
    }
    
    func testFromPersistedAmountMapsTenToCustomWithTen() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(10)
        XCTAssertEqual(adjustment, .custom)
        XCTAssertEqual(customAmount, 10)
    }
    
    func testFromPersistedAmountCoercesZeroToCustomWithOne() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(0)
        XCTAssertEqual(adjustment, .custom)
        XCTAssertEqual(customAmount, 1)
    }
    
    func testFromPersistedAmountCoercesNegativeToCustomWithOne() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(-3)
        XCTAssertEqual(adjustment, .custom)
        XCTAssertEqual(customAmount, 1)
    }
    
    func testFromPersistedAmountUsesDefaultPreviousCustomWhenNotProvided() {
        let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(1)
        XCTAssertEqual(adjustment, .one)
        XCTAssertEqual(customAmount, AdjustmentAmount.custom.defaultAmount)
    }
    
    func testDisplayTextForFixedCases() {
        XCTAssertEqual(AdjustmentAmount.one.displayText, "+1")
        XCTAssertEqual(AdjustmentAmount.five.displayText, "+5")
    }
    
    func testDisplayTextWithCustomAmountForCustomCase() {
        XCTAssertEqual(AdjustmentAmount.custom.displayText(customAmount: 7), "+7")
        XCTAssertEqual(AdjustmentAmount.custom.displayText(customAmount: 42), "+42")
    }
    
    func testDisplayTextWithCustomAmountForFixedCasesIgnoresCustomAmount() {
        XCTAssertEqual(AdjustmentAmount.one.displayText(customAmount: 99), "+1")
        XCTAssertEqual(AdjustmentAmount.five.displayText(customAmount: 99), "+5")
    }
}
