import XCTest
@testable import StitchCounter

@MainActor
final class AutoSaveDebouncerTests: XCTestCase {
    
    func testRapidReschedulesExecuteSaveOnce() async throws {
        var fireCount = 0
        let debouncer = AutoSaveDebouncerTestSupport.immediate()
        
        for _ in 0..<40 {
            debouncer.rescheduleDelayedSave(if: true) {
                fireCount += 1
            }
        }
        
        await Task.yield()
        XCTAssertEqual(fireCount, 1)
    }
    
    func testCancelBeforeDelayCompletesPreventsFire() async {
        var continuationToFinishDelay: (@Sendable () -> Void)?
        let sleepBegun = expectation(description: "delayed task reached sleep hook")
        
        let debouncer = AutoSaveDebouncer(
            delayNanoseconds: 1,
            performDelay: { (_: UInt64) async throws in
                sleepBegun.fulfill()
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    continuationToFinishDelay = {
                        continuation.resume()
                    }
                }
            }
        )
        
        var fireCount = 0
        debouncer.rescheduleDelayedSave(if: true) {
            fireCount += 1
        }
        
        await fulfillment(of: [sleepBegun], timeout: 2.0)
        debouncer.cancel()
        continuationToFinishDelay?()
        
        await Task.yield()
        XCTAssertEqual(fireCount, 0)
    }
    
    func testIneligibleScheduleOnlyCancelsAndDoesNotRunNewWork() async {
        var fireCount = 0
        let debouncer = AutoSaveDebouncerTestSupport.immediate()
        
        debouncer.rescheduleDelayedSave(if: true) {
            fireCount += 1
        }
        await Task.yield()
        XCTAssertEqual(fireCount, 1)
        
        debouncer.rescheduleDelayedSave(if: false) { }
        await Task.yield()
        
        XCTAssertEqual(fireCount, 1)
    }
}
