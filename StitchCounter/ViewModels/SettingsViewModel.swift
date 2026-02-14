import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportSuccess: Bool = false
    @Published var importSuccess: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var importedCount: Int = 0
    @Published var failedCount: Int = 0
    
    private let projectService: ProjectService
    
    init(projectService: ProjectService) {
        self.projectService = projectService
    }
    
    func exportLibrary() async -> URL? {
        isExporting = true
        exportError = nil
        
        defer { isExporting = false }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportError = "Could not access documents directory"
            return nil
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let exportFileName = "stitch_counter_backup_\(timestamp).json"
        let exportURL = documentsDirectory.appendingPathComponent(exportFileName)
        
        do {
            let projects = projectService.projects
            let exportData = projects.map { project in
                [
                    "id": project.id.uuidString,
                    "type": project.type.rawValue,
                    "title": project.title,
                    "stitchCounterNumber": project.stitchCounterNumber,
                    "stitchAdjustment": project.stitchAdjustment,
                    "rowCounterNumber": project.rowCounterNumber,
                    "rowAdjustment": project.rowAdjustment,
                    "totalRows": project.totalRows,
                    "imagePaths": project.imagePaths,
                    "createdAt": ISO8601DateFormatter().string(from: project.createdAt),
                    "updatedAt": ISO8601DateFormatter().string(from: project.updatedAt)
                ] as [String: Any]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            
            exportSuccess = true
            return exportURL
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importLibrary(from url: URL) async {
        isImporting = true
        importError = nil
        importedCount = 0
        failedCount = 0
        
        defer { isImporting = false }
        
        do {
            let data = try Data(contentsOf: url)
            guard let projectsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                importError = "Invalid backup format"
                return
            }
            
            for projectDict in projectsArray {
                guard let typeString = projectDict["type"] as? String,
                      let type = ProjectType(rawValue: typeString),
                      let title = projectDict["title"] as? String else {
                    failedCount += 1
                    continue
                }
                
                let newProject = projectService.createProject(type: type)
                newProject.title = title
                newProject.stitchCounterNumber = projectDict["stitchCounterNumber"] as? Int ?? 0
                newProject.stitchAdjustment = projectDict["stitchAdjustment"] as? Int ?? 1
                newProject.rowCounterNumber = projectDict["rowCounterNumber"] as? Int ?? 0
                newProject.rowAdjustment = projectDict["rowAdjustment"] as? Int ?? 1
                newProject.totalRows = projectDict["totalRows"] as? Int ?? 0
                
                projectService.saveProject(newProject)
                importedCount += 1
            }
            
            importSuccess = true
        } catch {
            importError = "Import failed: \(error.localizedDescription)"
        }
    }
    
    func clearExportStatus() {
        exportSuccess = false
        exportError = nil
    }
    
    func clearImportStatus() {
        importSuccess = false
        importError = nil
        importedCount = 0
        failedCount = 0
    }
}
