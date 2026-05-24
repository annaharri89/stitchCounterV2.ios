import Foundation

// Waits a bit before saving. If save gets triggered again, the wait starts over.
@MainActor
final class AutoSaveDebouncer {
    private var pendingSaveTask: Task<Void, Never>?
    private let delayNanoseconds: UInt64
    private let performDelay: (UInt64) async throws -> Void

    // performDelay is only needed in tests so they don't have to wait a full second.
    init(
        delayNanoseconds: UInt64 = 1_000_000_000,
        performDelay: @escaping (UInt64) async throws -> Void = { nanoseconds in
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    ) {
        self.delayNanoseconds = delayNanoseconds
        self.performDelay = performDelay
    }

    func cancel() {
        pendingSaveTask?.cancel()
    }

    func rescheduleDelayedSave(if eligible: Bool, perform action: @escaping @MainActor () -> Void) {
        pendingSaveTask?.cancel()
        guard eligible else { return }
        pendingSaveTask = Task { @MainActor in
            try? await performDelay(delayNanoseconds)
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
