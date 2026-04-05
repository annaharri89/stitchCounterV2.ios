import Foundation

enum ProjectImagePathResolver {
    static func fileURL(storedPath: String, documentsDirectory: URL) -> URL {
        if storedPath.hasPrefix("/") {
            URL(fileURLWithPath: storedPath)
        } else {
            documentsDirectory.appendingPathComponent(storedPath)
        }
    }

    static func absolutePathForLoading(storedPath: String, documentsDirectory: URL) -> String {
        fileURL(storedPath: storedPath, documentsDirectory: documentsDirectory).path
    }
}
