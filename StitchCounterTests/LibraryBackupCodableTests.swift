import XCTest
@testable import StitchCounter

final class LibraryBackupCodableTests: XCTestCase {
    func testBackupPayloadRoundTripMatchesAndroidKeyShape() throws {
        let metadata = BackupMetadata(
            version: 1,
            exportDate: 1_700_000_000_000,
            appVersion: "1.0",
            projectCount: 1
        )
        let project = BackupProjectSnapshot(
            id: 1,
            type: "single",
            title: "Test",
            notes: "",
            stitchCounterNumber: 0,
            stitchAdjustment: 1,
            rowCounterNumber: 0,
            rowAdjustment: 1,
            totalRows: 0,
            imagePaths: ["project_images/a.jpg"],
            createdAt: 1_700_000_000_000,
            updatedAt: 1_700_000_000_000,
            completedAt: nil,
            totalStitchesEver: 0
        )
        let payload = BackupPayload(metadata: metadata, projects: [project])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(payload)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"export_date\""))
        XCTAssertTrue(json.contains("\"stitch_counter_number\""))
        XCTAssertTrue(json.contains("\"image_paths\""))

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BackupPayload.self, from: data)
        XCTAssertEqual(decoded.metadata.version, 1)
        XCTAssertEqual(decoded.projects.count, 1)
        XCTAssertEqual(decoded.projects[0].type, "single")
        XCTAssertEqual(decoded.projects[0].imagePaths, ["project_images/a.jpg"])
    }
}
