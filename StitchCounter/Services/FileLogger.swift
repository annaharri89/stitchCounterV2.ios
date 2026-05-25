import Foundation

enum FileLogLevel: String {
    case debug
    case info
    case warning
    case error
}

struct FileLogEntry: Encodable {
    let timestamp: String
    let level: String
    let tag: String
    let message: String
    let metadata: [String: String]?
}

protocol FileLogging {
    var logsDirectoryURL: URL { get }
    func initializeLogging()
    func debug(tag: String, message: String, metadata: [String: String]?)
    func info(tag: String, message: String, metadata: [String: String]?)
    func warning(tag: String, message: String, metadata: [String: String]?)
    func error(tag: String, message: String, metadata: [String: String]?)
}

final class FileLogger: FileLogging {
    static let shared = FileLogger()

    let logsDirectoryURL: URL

    private let retentionPolicy: LogRetentionPolicy
    private let fileManager: FileManager
    private let writeQueue: DispatchQueue
    private let encoder: JSONEncoder
    private let iso8601Formatter: ISO8601DateFormatter
    private let filePrefix = "stitch_counter_log_"
    private let fileExtension = "log"

    init(
        logsDirectoryURL: URL? = nil,
        retentionPolicy: LogRetentionPolicy = .bugReportDefault,
        fileManager: FileManager = .default
    ) {
        let defaultDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("logs", isDirectory: true)
            ?? fileManager.temporaryDirectory.appendingPathComponent("logs", isDirectory: true)
        self.logsDirectoryURL = logsDirectoryURL ?? defaultDirectory
        self.retentionPolicy = retentionPolicy
        self.fileManager = fileManager
        self.writeQueue = DispatchQueue(label: "com.stitchcounter.filelogger.write", qos: .utility)
        self.encoder = JSONEncoder()
        self.iso8601Formatter = ISO8601DateFormatter()
        self.iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func initializeLogging() {
        writeQueue.async {
            self.ensureLogDirectoryExists()
            self.pruneOldLogFilesIfNeeded()
        }
    }

    func debug(tag: String, message: String, metadata: [String: String]? = nil) {
        log(level: .debug, tag: tag, message: message, metadata: metadata)
    }

    func info(tag: String, message: String, metadata: [String: String]? = nil) {
        log(level: .info, tag: tag, message: message, metadata: metadata)
    }

    func warning(tag: String, message: String, metadata: [String: String]? = nil) {
        log(level: .warning, tag: tag, message: message, metadata: metadata)
    }

    func error(tag: String, message: String, metadata: [String: String]? = nil) {
        log(level: .error, tag: tag, message: message, metadata: metadata)
    }

    private func log(level: FileLogLevel, tag: String, message: String, metadata: [String: String]?) {
        let normalizedTag = tag.isEmpty ? "General" : tag
        writeQueue.async {
            self.ensureLogDirectoryExists()
            let now = Date()
            let entry = FileLogEntry(
                timestamp: self.iso8601Formatter.string(from: now),
                level: level.rawValue,
                tag: normalizedTag,
                message: message,
                metadata: metadata?.isEmpty == true ? nil : metadata
            )
            guard let lineData = self.encodedLineData(for: entry) else { return }
            guard let activeLogFile = self.activeLogFileURL(requiredAdditionalBytes: lineData.count) else { return }
            if self.fileManager.fileExists(atPath: activeLogFile.path) {
                do {
                    let fileHandle = try FileHandle(forWritingTo: activeLogFile)
                    try fileHandle.seekToEnd()
                    try fileHandle.write(contentsOf: lineData)
                    try fileHandle.close()
                } catch {
                    try? lineData.write(to: activeLogFile, options: .atomic)
                }
            } else {
                try? lineData.write(to: activeLogFile, options: .atomic)
            }
            self.pruneOldLogFilesIfNeeded()
        }
    }

    private func encodedLineData(for entry: FileLogEntry) -> Data? {
        guard let encoded = try? encoder.encode(entry) else { return nil }
        var lineData = encoded
        lineData.append(0x0A)
        return lineData
    }

    private func ensureLogDirectoryExists() {
        guard !fileManager.fileExists(atPath: logsDirectoryURL.path) else { return }
        try? fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
    }

    private func activeLogFileURL(requiredAdditionalBytes: Int) -> URL? {
        let existingFiles = sortedLogFiles()
        if let latest = existingFiles.last {
            let currentSize = fileSize(for: latest)
            if currentSize + requiredAdditionalBytes <= retentionPolicy.maxBytesPerFile {
                return latest
            }
        }
        return newLogFileURL()
    }

    private func newLogFileURL() -> URL? {
        let fileName = "\(filePrefix)\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString).\(fileExtension)"
        return logsDirectoryURL.appendingPathComponent(fileName)
    }

    private func pruneOldLogFilesIfNeeded() {
        let files = sortedLogFiles()
        guard files.count > retentionPolicy.maxFileCount else { return }
        let removableCount = files.count - retentionPolicy.maxFileCount
        for file in files.prefix(removableCount) {
            try? fileManager.removeItem(at: file)
        }
    }

    private func sortedLogFiles() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: logsDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return files
            .filter { $0.pathExtension == fileExtension && $0.lastPathComponent.hasPrefix(filePrefix) }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return lhsDate < rhsDate
            }
    }

    private func fileSize(for fileURL: URL) -> Int {
        let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
        return attributes?[.size] as? Int ?? 0
    }
}
