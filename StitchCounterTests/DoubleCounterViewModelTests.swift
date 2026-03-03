import XCTest
@testable import StitchCounter

@MainActor
final class DoubleCounterViewModelTests: XCTestCase {
    
    private var mockService: MockProjectService!
    
    override func setUp() {
        super.setUp()
        mockService = MockProjectService()
    }
    
    private func createViewModel() -> DoubleCounterViewModel {
        DoubleCounterViewModel(projectService: mockService)
    }
    
    private func sampleProject(
        id: UUID = UUID(),
        stitchAdjustment: Int = 1,
        rowAdjustment: Int = 1,
        stitchCounterNumber: Int = 10,
        rowCounterNumber: Int = 5,
        totalRows: Int = 20,
        totalStitchesEver: Int = 50
    ) -> Project {
        Project(
            id: id,
            type: .double,
            title: "Test Blanket",
            stitchCounterNumber: stitchCounterNumber,
            stitchAdjustment: stitchAdjustment,
            rowCounterNumber: rowCounterNumber,
            rowAdjustment: rowAdjustment,
            totalRows: totalRows,
            totalStitchesEver: totalStitchesEver
        )
    }
    
    // MARK: - setCustomAdjustmentAmount per counter type
    
    func testSetCustomAdjustmentAmountUpdatesStitchCounterOnly() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.stitch, value: 7)
        
        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.stitchCounterState.customAdjustmentAmount, 7)
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .one)
    }
    
    func testSetCustomAdjustmentAmountUpdatesRowCounterOnly() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.row, value: 3)
        
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.rowCounterState.customAdjustmentAmount, 3)
        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .one)
    }
    
    func testSetCustomAdjustmentAmountCoercesStitchValueToAtLeastOne() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.stitch, value: 0)
        
        XCTAssertEqual(viewModel.stitchCounterState.customAdjustmentAmount, 1)
    }
    
    func testSetCustomAdjustmentAmountCoercesRowValueToAtLeastOne() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.row, value: -5)
        
        XCTAssertEqual(viewModel.rowCounterState.customAdjustmentAmount, 1)
    }
    
    // MARK: - increment uses resolvedAdjustmentAmount
    
    func testIncrementStitchUsesResolvedAdjustmentAmountForTotalStitchesEver() {
        let project = sampleProject(stitchAdjustment: 7, stitchCounterNumber: 0, totalStitchesEver: 100)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.increment(.stitch)
        
        XCTAssertEqual(viewModel.totalStitchesEver, 107)
    }
    
    func testIncrementStitchWithCustomAdjustmentAddsCorrectAmount() {
        let project = sampleProject(stitchCounterNumber: 0)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(.stitch, value: 8)
        viewModel.increment(.stitch)
        
        XCTAssertEqual(viewModel.stitchCounterState.count, 8)
    }
    
    // MARK: - loadProject reconstructs from persisted values
    
    func testLoadProjectReconstructsBothCountersFromPersistedValues() {
        let project = sampleProject(stitchAdjustment: 7, rowAdjustment: 3)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.stitchCounterState.customAdjustmentAmount, 7)
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.rowCounterState.customAdjustmentAmount, 3)
    }
    
    func testLoadProjectReconstructsStandardAdjustments() {
        let project = sampleProject(stitchAdjustment: 1, rowAdjustment: 5)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .one)
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .five)
    }
    
    // MARK: - save persists resolvedAdjustmentAmount
    
    func testSavePersistsBothResolvedAdjustmentAmountValues() {
        let project = sampleProject(stitchAdjustment: 1, rowAdjustment: 1)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(.stitch, value: 12)
        viewModel.setCustomAdjustmentAmount(.row, value: 3)
        viewModel.save()
        
        XCTAssertEqual(project.stitchAdjustment, 12)
        XCTAssertEqual(project.rowAdjustment, 3)
    }

    func testChangeAdjustmentPreservesCustomAmountWhenSwitchingAwayAndBackForStitch() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.stitch, value: 8)
        viewModel.changeAdjustment(.stitch, value: .one)
        viewModel.changeAdjustment(.stitch, value: .custom)

        XCTAssertEqual(viewModel.stitchCounterState.customAdjustmentAmount, 8)
        XCTAssertEqual(viewModel.stitchCounterState.resolvedAdjustmentAmount, 8)
    }

    func testChangeAdjustmentPreservesCustomAmountWhenSwitchingAwayAndBackForRow() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(.row, value: 4)
        viewModel.changeAdjustment(.row, value: .five)
        viewModel.changeAdjustment(.row, value: .custom)

        XCTAssertEqual(viewModel.rowCounterState.customAdjustmentAmount, 4)
        XCTAssertEqual(viewModel.rowCounterState.resolvedAdjustmentAmount, 4)
    }

    func testLoadProjectPreserveCountersKeepsInMemoryCustomState() {
        let project = sampleProject(
            stitchAdjustment: 7,
            rowAdjustment: 3,
            stitchCounterNumber: 10,
            rowCounterNumber: 5,
            totalRows: 20,
            totalStitchesEver: 50
        )
        mockService.addProject(project)

        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(.stitch, value: 9)
        viewModel.setCustomAdjustmentAmount(.row, value: 2)
        viewModel.increment(.stitch)
        viewModel.increment(.row)

        project.stitchAdjustment = 1
        project.rowAdjustment = 5
        project.stitchCounterNumber = 1
        project.rowCounterNumber = 1
        project.totalStitchesEver = 1
        viewModel.loadProject(project.id)

        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.stitchCounterState.customAdjustmentAmount, 9)
        XCTAssertEqual(viewModel.stitchCounterState.count, 19)
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .custom)
        XCTAssertEqual(viewModel.rowCounterState.customAdjustmentAmount, 2)
        XCTAssertEqual(viewModel.rowCounterState.count, 7)
        XCTAssertEqual(viewModel.totalStitchesEver, 59)
    }

    func testSaveCallsProjectServiceWithUpdatedValuesForBothCounters() {
        let project = sampleProject(stitchAdjustment: 1, rowAdjustment: 1, stitchCounterNumber: 10, rowCounterNumber: 5, totalRows: 20, totalStitchesEver: 50)
        mockService.addProject(project)

        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(.stitch, value: 6)
        viewModel.setCustomAdjustmentAmount(.row, value: 4)
        viewModel.increment(.stitch)
        viewModel.increment(.row)
        viewModel.save()

        XCTAssertEqual(mockService.savedProjects.count, 1)
        XCTAssertEqual(mockService.savedProjects.last?.id, project.id)
        XCTAssertEqual(mockService.savedProjects.last?.stitchCounterNumber, 16)
        XCTAssertEqual(mockService.savedProjects.last?.stitchAdjustment, 6)
        XCTAssertEqual(mockService.savedProjects.last?.rowCounterNumber, 9)
        XCTAssertEqual(mockService.savedProjects.last?.rowAdjustment, 4)
        XCTAssertEqual(mockService.savedProjects.last?.totalStitchesEver, 56)
    }
    
    // MARK: - Row counter capped at totalRows
    
    func testRowCounterCappedAtTotalRowsEvenWithCustomAmount() {
        let project = sampleProject(rowCounterNumber: 18, totalRows: 20)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(.row, value: 5)
        viewModel.increment(.row)
        
        XCTAssertEqual(viewModel.rowCounterState.count, 20)
    }
    
    // MARK: - Basic operations
    
    func testLoadProjectPopulatesState() {
        let project = sampleProject()
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.projectId, project.id)
        XCTAssertEqual(viewModel.title, "Test Blanket")
        XCTAssertEqual(viewModel.stitchCounterState.count, 10)
        XCTAssertEqual(viewModel.rowCounterState.count, 5)
        XCTAssertEqual(viewModel.totalRows, 20)
        XCTAssertEqual(viewModel.totalStitchesEver, 50)
    }
    
    func testLoadProjectWithNilResetsState() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil)
        
        XCTAssertNil(viewModel.projectId)
        XCTAssertEqual(viewModel.stitchCounterState.count, 0)
        XCTAssertEqual(viewModel.rowCounterState.count, 0)
    }
    
    func testChangeAdjustmentUpdatesCorrectCounter() {
        let viewModel = createViewModel()
        viewModel.changeAdjustment(.stitch, value: .five)
        
        XCTAssertEqual(viewModel.stitchCounterState.adjustment, .five)
        XCTAssertEqual(viewModel.rowCounterState.adjustment, .one)
    }
    
    func testResetAllSetsAllCountsToZero() {
        let project = sampleProject()
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.resetAll()
        
        XCTAssertEqual(viewModel.stitchCounterState.count, 0)
        XCTAssertEqual(viewModel.rowCounterState.count, 0)
    }
    
    func testRowProgressIsNilWhenTotalRowsIsZero() {
        let project = sampleProject(totalRows: 0)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertNil(viewModel.rowProgress)
    }
    
    func testRowProgressCalculatesCorrectly() {
        let project = sampleProject(rowCounterNumber: 10, totalRows: 20)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.rowProgress!, 0.5, accuracy: 0.001)
    }
    
    func testResetStateClearsEverything() {
        let project = sampleProject()
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.resetState()
        
        XCTAssertNil(viewModel.projectId)
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.stitchCounterState.count, 0)
        XCTAssertEqual(viewModel.rowCounterState.count, 0)
        XCTAssertEqual(viewModel.totalRows, 0)
        XCTAssertEqual(viewModel.totalStitchesEver, 0)
    }
}
