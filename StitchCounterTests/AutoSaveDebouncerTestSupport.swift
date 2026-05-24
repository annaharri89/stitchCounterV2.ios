import Foundation
@testable import StitchCounter

enum AutoSaveDebouncerTestSupport {
    @MainActor
    static func immediate() -> AutoSaveDebouncer {
        AutoSaveDebouncer(
            delayNanoseconds: 0,
            performDelay: { (_: UInt64) async throws in () }
        )
    }
}
