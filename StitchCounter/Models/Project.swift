import Foundation
import SwiftData

enum ProjectType: String, Codable, CaseIterable {
    case single
    case double
}

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var type: ProjectType
    var title: String
    var notes: String
    var stitchCounterNumber: Int
    var stitchAdjustment: Int
    var rowCounterNumber: Int
    var rowAdjustment: Int
    var totalRows: Int
    var imagePaths: [String]
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var totalStitchesEver: Int
    
    init(
        id: UUID = UUID(),
        type: ProjectType,
        title: String = "",
        notes: String = "",
        stitchCounterNumber: Int = 0,
        stitchAdjustment: Int = 1,
        rowCounterNumber: Int = 0,
        rowAdjustment: Int = 1,
        totalRows: Int = 0,
        imagePaths: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        totalStitchesEver: Int = 0
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.notes = notes
        self.stitchCounterNumber = stitchCounterNumber
        self.stitchAdjustment = stitchAdjustment
        self.rowCounterNumber = rowCounterNumber
        self.rowAdjustment = rowAdjustment
        self.totalRows = totalRows
        self.imagePaths = imagePaths
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.totalStitchesEver = totalStitchesEver
    }
}
