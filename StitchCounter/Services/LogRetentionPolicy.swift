import Foundation

struct LogRetentionPolicy: Equatable {
    let maxFileCount: Int
    let maxBytesPerFile: Int

    static let bugReportDefault = LogRetentionPolicy(
        maxFileCount: 5,
        maxBytesPerFile: 256 * 1024
    )
}
