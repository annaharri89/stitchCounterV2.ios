import XCTest
@testable import StitchCounter

final class LibraryBackupZipEligibilityTests: XCTestCase {
    func testTreatsPkSignatureAsZip() {
        let data = Data([0x50, 0x4B, 0x03, 0x04])
        XCTAssertTrue(LibraryBackupManager.shouldTreatAsZipImport(fileData: data, pathExtension: "txt"))
    }

    func testTreatsZipExtensionAsZip() {
        let data = Data([0x00])
        XCTAssertTrue(LibraryBackupManager.shouldTreatAsZipImport(fileData: data, pathExtension: "zip"))
    }

    func testRejectsPlainJsonWithoutZipExtension() {
        let data = Data(#"{"metadata":{}}"#.utf8)
        XCTAssertFalse(LibraryBackupManager.shouldTreatAsZipImport(fileData: data, pathExtension: "json"))
    }
}
