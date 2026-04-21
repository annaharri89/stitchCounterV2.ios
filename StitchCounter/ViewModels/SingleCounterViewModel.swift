import SwiftUI
import Combine

@MainActor
final class SingleCounterViewModel: ObservableObject {
    @Published var projectId: UUID?
    @Published var title: String = ""
    @Published var counterState: CounterState = CounterState()
    @Published var totalStitchesEver: Int = 0
    @Published var isLoading: Bool = false
    
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
        
        let preserveCounter = projectId == project.id && projectId != nil
        projectId = project.id
        title = project.title
        
        if !preserveCounter {
            let (adjustment, customAmount) = AdjustmentAmount.fromPersistedAmount(project.stitchAdjustment)
            counterState = CounterState(
                count: project.stitchCounterNumber,
                adjustment: adjustment,
                customAdjustmentAmount: customAmount
            )
            totalStitchesEver = project.totalStitchesEver
        }
    }
    
    func increment() {
        totalStitchesEver += counterState.resolvedAdjustmentAmount
        counterState = counterState.incremented()
        triggerAutoSave()
    }
    
    func decrement() {
        counterState = counterState.decremented()
        triggerAutoSave()
    }
    
    func resetCount() {
        counterState = counterState.reset()
        triggerAutoSave()
    }
    
    func changeAdjustment(_ value: AdjustmentAmount) {
        counterState = counterState.withAdjustment(value)
        triggerAutoSave()
    }
    
    func setCustomAdjustmentAmount(_ value: Int) {
        counterState = counterState.withCustomAdjustmentAmount(value)
        triggerAutoSave()
    }
    
    func resetState() {
        projectId = nil
        title = ""
        counterState = CounterState()
        totalStitchesEver = 0
    }
    
    private func triggerAutoSave() {
        autoSaveTask?.cancel()
        guard projectId != nil else { return }
        
        autoSaveTask = Task {
            try? await Task.sleep(nanoseconds: autoSaveDelayNanoseconds)
            guard !Task.isCancelled else { return }
            save()
        }
    }
    
    func save() {
        guard let projectId = projectId,
              let project = projectService.getProject(by: projectId) else { return }
        
        project.stitchCounterNumber = counterState.count
        project.stitchAdjustment = counterState.resolvedAdjustmentAmount
        project.totalStitchesEver = totalStitchesEver
        projectService.saveProject(project)
    }
    
    func attemptDismissal() {
        autoSaveTask?.cancel()
        save()
    }
}
