import Foundation
import ZIPFoundation

private let backupJsonFileName = "backup.json"
private let backupImagesDirectoryName = "images"
private let internalProjectImagesDirectory = "project_images"
private let supportedBackupVersion = 1

struct BackupMetadata: Codable, Equatable {
    var version: Int
    var exportDate: Int64
    var appVersion: String
    var projectCount: Int

    enum CodingKeys: String, CodingKey {
        case version
        case exportDate = "export_date"
        case appVersion = "app_version"
        case projectCount = "project_count"
    }
}

struct BackupProjectSnapshot: Codable, Equatable {
    var id: Int
    var type: String
    var title: String
    var notes: String
    var stitchCounterNumber: Int
    var stitchAdjustment: Int
    var rowCounterNumber: Int
    var rowAdjustment: Int
    var totalRows: Int
    var imagePaths: [String]
    var createdAt: Int64
    var updatedAt: Int64
    var completedAt: Int64?
    var totalStitchesEver: Int

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case notes
        case stitchCounterNumber = "stitch_counter_number"
        case stitchAdjustment = "stitch_adjustment"
        case rowCounterNumber = "row_counter_number"
        case rowAdjustment = "row_adjustment"
        case totalRows = "total_rows"
        case imagePaths = "image_paths"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case totalStitchesEver = "total_stitches_ever"
    }
}

struct BackupPayload: Codable, Equatable {
    var metadata: BackupMetadata
    var projects: [BackupProjectSnapshot]

    enum CodingKeys: String, CodingKey {
        case metadata
        case projects
    }
}

struct LibraryImportResult: Equatable {
    var importedCount: Int
    var failedCount: Int
    var failedProjectNames: [String]
}

enum LibraryBackupError: Error, Equatable {
    case documentsDirectoryUnavailable
    case cannotCreateArchive
    case cannotReadArchive
    case backupJsonMissing
    case unsupportedBackupVersion(Int)
    case unsafeZipEntry(String)
    case invalidBackupPayload
    case unexpectedUnderlying(String)
    case notZipFile
}

enum LibraryBackupManager {
    private static let logTag = "LibraryBackup"

    static func shouldTreatAsZipImport(fileData: Data, pathExtension: String) -> Bool {
        let hasZipSignature = fileData.count >= 2 && fileData[0] == 0x50 && fileData[1] == 0x4B
        return hasZipSignature || pathExtension.lowercased() == "zip"
    }

    static func exportZip(
        projects: [Project],
        documentsDirectory: URL,
        appVersion: String
    ) throws -> URL {
        let fileManager = FileManager.default
        let cacheRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? documentsDirectory
        let tempName = "backup_temp_\(UUID().uuidString)"
        let tempDir = cacheRoot.appendingPathComponent(tempName, isDirectory: true)
        let imagesRoot = tempDir.appendingPathComponent(backupImagesDirectoryName, isDirectory: true)

        try fileManager.createDirectory(at: imagesRoot, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var snapshots: [BackupProjectSnapshot] = []
        snapshots.reserveCapacity(projects.count)

        for (index, project) in projects.enumerated() {
            let backupId = index + 1
            var remappedPaths: [String] = []

            for storedPath in project.imagePaths {
                let sourceURL = ProjectImagePathResolver.fileURL(storedPath: storedPath, documentsDirectory: documentsDirectory)
                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    print("[\(logTag)] event=export_image_missing path=\(storedPath)")
                    continue
                }
                let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
                let destName =
                    "project_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(8)).\(ext)"
                let relative = "\(internalProjectImagesDirectory)/\(destName)"
                let destURL = imagesRoot.appendingPathComponent(relative)
                try fileManager.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: sourceURL, to: destURL)
                remappedPaths.append(relative)
            }

            let createdMs = Int64(project.createdAt.timeIntervalSince1970 * 1000)
            let updatedMs = Int64(project.updatedAt.timeIntervalSince1970 * 1000)
            let completedMs = project.completedAt.map { Int64($0.timeIntervalSince1970 * 1000) }

            snapshots.append(
                BackupProjectSnapshot(
                    id: backupId,
                    type: project.type.rawValue,
                    title: project.title,
                    notes: project.notes,
                    stitchCounterNumber: project.stitchCounterNumber,
                    stitchAdjustment: project.stitchAdjustment,
                    rowCounterNumber: project.rowCounterNumber,
                    rowAdjustment: project.rowAdjustment,
                    totalRows: project.totalRows,
                    imagePaths: remappedPaths,
                    createdAt: createdMs,
                    updatedAt: updatedMs,
                    completedAt: completedMs,
                    totalStitchesEver: project.totalStitchesEver
                )
            )
        }

        let metadata = BackupMetadata(
            version: supportedBackupVersion,
            exportDate: Int64(Date().timeIntervalSince1970 * 1000),
            appVersion: appVersion,
            projectCount: projects.count
        )
        let payload = BackupPayload(metadata: metadata, projects: snapshots)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.keyEncodingStrategy = .useDefaultKeys
        let jsonData = try encoder.encode(payload)
        let jsonURL = tempDir.appendingPathComponent(backupJsonFileName)
        try jsonData.write(to: jsonURL)

        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.timeZone = TimeZone(identifier: "UTC")
        timestampFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let zipName = "stitch_counter_backup_\(timestampFormatter.string(from: Date())).zip"
        let zipURL = documentsDirectory.appendingPathComponent(zipName)

        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }

        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            try? fileManager.removeItem(at: tempDir)
            throw LibraryBackupError.cannotCreateArchive
        }

        let baseDir = tempDir.standardizedFileURL
        let enumerator = fileManager.enumerator(at: tempDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        while let item = enumerator?.nextObject() as? URL {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: item.path, isDirectory: &isDir), !isDir.boolValue else { continue }
            let full = item.standardizedFileURL
            let prefix = baseDir.path + "/"
            guard full.path.hasPrefix(prefix) else { continue }
            let entryPath = String(full.path.dropFirst(prefix.count)).replacingOccurrences(of: "\\", with: "/")
            try archive.addEntry(with: entryPath, fileURL: item, compressionMethod: .deflate)
        }

        try fileManager.removeItem(at: tempDir)
        return zipURL
    }

    static func importFromZip(
        zipURL: URL,
        documentsDirectory: URL,
        insertProject: (Project) -> Void
    ) throws -> LibraryImportResult {
        let fileManager = FileManager.default
        let cacheRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? documentsDirectory
        let extractDir = cacheRoot.appendingPathComponent("backup_extract_\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: extractDir)
        }

        guard let archive = Archive(url: zipURL, accessMode: .read) else {
            throw LibraryBackupError.cannotReadArchive
        }

        let extractRoot = extractDir.standardizedFileURL
        for entry in archive {
            guard !entry.path.hasSuffix("/") else { continue }
            let destinationURL = extractDir.appendingPathComponent(entry.path).standardizedFileURL
            guard destinationURL.isStrictSubpath(of: extractRoot) else {
                throw LibraryBackupError.unsafeZipEntry(entry.path)
            }
            try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            _ = try archive.extract(entry, to: destinationURL)
        }

        let jsonURL = extractDir.appendingPathComponent(backupJsonFileName)
        guard fileManager.fileExists(atPath: jsonURL.path) else {
            throw LibraryBackupError.backupJsonMissing
        }

        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let payload = try decoder.decode(BackupPayload.self, from: data)

        if payload.metadata.version != supportedBackupVersion {
            throw LibraryBackupError.unsupportedBackupVersion(payload.metadata.version)
        }

        let imagesDir = extractDir.appendingPathComponent(backupImagesDirectoryName, isDirectory: true)
        let imagesRoot = imagesDir.standardizedFileURL
        var importedCount = 0
        var failedNames: [String] = []

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)

        for snapshot in payload.projects {
            do {
                guard let type = ProjectType(rawValue: snapshot.type) else {
                    throw LibraryBackupError.invalidBackupPayload
                }

                var storedImagePaths: [String] = []
                for relativeImagePath in snapshot.imagePaths {
                    let source = imagesDir.appendingPathComponent(relativeImagePath).standardizedFileURL
                    guard source.isStrictSubpath(of: imagesRoot), fileManager.fileExists(atPath: source.path) else {
                        print("[\(logTag)] event=import_image_missing path=\(relativeImagePath)")
                        continue
                    }
                    if let copied = copyImportedImageToDocuments(sourceFile: source, documentsDirectory: documentsDirectory) {
                        storedImagePaths.append(copied)
                    }
                }

                let project = Project(
                    type: type,
                    title: snapshot.title,
                    notes: snapshot.notes,
                    stitchCounterNumber: snapshot.stitchCounterNumber,
                    stitchAdjustment: snapshot.stitchAdjustment,
                    rowCounterNumber: snapshot.rowCounterNumber,
                    rowAdjustment: snapshot.rowAdjustment,
                    totalRows: snapshot.totalRows,
                    imagePaths: storedImagePaths,
                    createdAt: dateFromMillis(snapshot.createdAt) ?? Date(timeIntervalSince1970: TimeInterval(nowMs) / 1000),
                    updatedAt: dateFromMillis(snapshot.updatedAt) ?? Date(timeIntervalSince1970: TimeInterval(nowMs) / 1000),
                    completedAt: snapshot.completedAt.flatMap(dateFromMillis),
                    totalStitchesEver: snapshot.totalStitchesEver
                )

                insertProject(project)
                importedCount += 1
            } catch {
                failedNames.append("\(snapshot.title) (ID: \(snapshot.id))")
                print("[\(logTag)] event=import_project_failed id=\(snapshot.id) title=\(snapshot.title) error=\(error)")
            }
        }

        return LibraryImportResult(
            importedCount: importedCount,
            failedCount: failedNames.count,
            failedProjectNames: failedNames
        )
    }

    private static func dateFromMillis(_ millis: Int64) -> Date? {
        guard millis > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
    }

    private static func copyImportedImageToDocuments(sourceFile: URL, documentsDirectory: URL) -> String? {
        let fileManager = FileManager.default
        let imagesDir = documentsDirectory.appendingPathComponent(internalProjectImagesDirectory, isDirectory: true)
        do {
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            let ext = sourceFile.pathExtension.isEmpty ? "jpg" : sourceFile.pathExtension
            let destName = "project_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString).\(ext)"
            let destURL = imagesDir.appendingPathComponent(destName)
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: sourceFile, to: destURL)
            return "\(internalProjectImagesDirectory)/\(destName)"
        } catch {
            print("[\(logTag)] event=copy_import_image_failed error=\(error)")
            return nil
        }
    }
}

private extension URL {
    func isStrictSubpath(of parent: URL) -> Bool {
        let child = standardizedFileURL.path
        let root = parent.standardizedFileURL.path
        guard child != root else { return true }
        let prefix = root.hasSuffix("/") ? root : root + "/"
        return child.hasPrefix(prefix)
    }
}
