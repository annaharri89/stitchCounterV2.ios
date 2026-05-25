import XCTest
@testable import StitchCounter

final class FileLoggerTests: XCTestCase {
    private var tempDirectoryURL: URL!

    override func setUpWithError() throws {
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("file_logger_tests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
    }

    func testLoggerRotatesFilesAndPrunesOldLogs() throws {
        let logger = FileLogger(
            logsDirectoryURL: tempDirectoryURL,
            retentionPolicy: LogRetentionPolicy(maxFileCount: 2, maxBytesPerFile: 256)
        )
        logger.initializeLogging()

        for index in 0..<200 {
            logger.info(
                tag: "FileLoggerTests",
                message: "message_\(index)_\(String(repeating: "x", count: 40))",
                metadata: ["index": "\(index)"]
            )
        }

        waitForFileWrites()

        let logFiles = try FileManager.default.contentsOfDirectory(
            at: tempDirectoryURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        XCTAssertLessThanOrEqual(logFiles.count, 2)
        XCTAssertFalse(logFiles.isEmpty)

        for fileURL in logFiles {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let byteCount = attributes[.size] as? Int ?? 0
            XCTAssertLessThanOrEqual(byteCount, 256)
        }
    }

    private func waitForFileWrites() {
        let expectation = expectation(description: "wait_for_logger_flush")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
