import SwiftUI
import Combine

@MainActor
final class DoubleCounterViewModel: ObservableObject {
    @Published var projectId: UUID?
    @Published var title: String = ""
    @Published var stitchCounterState: CounterState = CounterState()
    @Published var rowCounterState: CounterState = CounterState()
    @Published var totalRows: Int = 0
    @Published var totalStitchesEver: Int = 0
    @Published var isLoading: Bool = false
    
    var rowProgress: Float? {
        guard totalRows > 0 else { return nil }
        return min(1.0, Float(rowCounterState.count) / Float(totalRows))
    }
    
    private let projectService: ProjectServiceProtocol
    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveDelayNanoseconds: UInt64 = 1_000_000_000
    
    init(projectService: ProjectServiceProtocol) {
        self.projectService = projectService
    }
    
    func loadProject(_ id: UUID?) {
        guard let id = id else {
            resetState()
            return
        }
        
        guard let project = projectService.getProject(by: id) else {
            resetState()
            return
        }
        
        let preserveCounters = projectId == project.id && projectId != nil
        projectId = project.id
        title = project.title
        totalRows = project.totalRows
        
        if !preserveCounters {
            let (stitchAdjustment, stitchCustom) = AdjustmentAmount.fromPersistedAmount(project.stitchAdjustment)
            let (rowAdjustment, rowCustom) = AdjustmentAmount.fromPersistedAmount(project.rowAdjustment)
            stitchCounterState = CounterState(
                count: project.stitchCounterNumber,
                adjustment: stitchAdjustment,
                customAdjustmentAmount: stitchCustom
            )
            rowCounterState = CounterState(
                count: project.rowCounterNumber,
                adjustment: rowAdjustment,
                customAdjustmentAmount: rowCustom
            )
            totalStitchesEver = project.totalStitchesEver
        }
    }
    
    func increment(_ type: CounterType) {
        if type == .stitch {
            totalStitchesEver += stitchCounterState.resolvedAdjustmentAmount
        }
        updateCounter(type) { $0.incremented() }
    }
    
    func decrement(_ type: CounterType) {
        updateCounter(type) { $0.decremented() }
    }
    
    func reset(_ type: CounterType) {
        updateCounter(type) { $0.reset() }
    }
    
    func changeAdjustment(_ type: CounterType, value: AdjustmentAmount) {
        updateCounter(type) { $0.withAdjustment(value) }
    }
    
    func setCustomAdjustmentAmount(_ type: CounterType, value: Int) {
        updateCounter(type) { $0.withCustomAdjustmentAmount(value) }
    }
    
    func resetAll() {
        reset(.stitch)
        reset(.row)
    }
    
    private func updateCounter(_ type: CounterType, transform: (CounterState) -> CounterState) {
        switch type {
        case .stitch:
            stitchCounterState = transform(stitchCounterState)
        case .row:
            var newState = transform(rowCounterState)
            if totalRows > 0 {
                newState = CounterState(
                    count: min(newState.count, totalRows),
                    adjustment: newState.adjustment,
                    customAdjustmentAmount: newState.customAdjustmentAmount
                )
            }
            rowCounterState = newState
        }
        triggerAutoSave()
    }
    
    func resetState() {
        projectId = nil
        title = ""
        stitchCounterState = CounterState()
        rowCounterState = CounterState()
        totalRows = 0
        totalStitchesEver = 0
    }
    
    private func triggerAutoSave() {
        autoSaveTask?.cancel()
        guard let projectId = projectId else { return }
        
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: autoSaveDelayNanoseconds)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    
    func save() {
        guard let projectId = projectId,
              let project = projectService.getProject(by: projectId) else { return }
        
        project.stitchCounterNumber = stitchCounterState.count
        project.stitchAdjustment = stitchCounterState.resolvedAdjustmentAmount
        project.rowCounterNumber = rowCounterState.count
        project.rowAdjustment = rowCounterState.resolvedAdjustmentAmount
        project.totalStitchesEver = totalStitchesEver
        projectService.saveProject(project)
    }
    
    func attemptDismissal() {
        autoSaveTask?.cancel()
        save()
    }
}
