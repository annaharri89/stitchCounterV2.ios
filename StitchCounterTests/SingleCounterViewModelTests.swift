import XCTest
@testable import StitchCounter

@MainActor
final class SingleCounterViewModelTests: XCTestCase {
    
    private var mockService: MockProjectService!
    
    override func setUp() {
        super.setUp()
        mockService = MockProjectService()
    }
    
    private func createViewModel() -> SingleCounterViewModel {
        SingleCounterViewModel(projectService: mockService)
    }
    
    private func sampleProject(
        id: UUID = UUID(),
        stitchAdjustment: Int = 1,
        stitchCounterNumber: Int = 10,
        totalStitchesEver: Int = 50
    ) -> Project {
        Project(
            id: id,
            type: .single,
            title: "Test Scarf",
            stitchCounterNumber: stitchCounterNumber,
            stitchAdjustment: stitchAdjustment,
            totalStitchesEver: totalStitchesEver
        )
    }
    
    // MARK: - setCustomAdjustmentAmount
    
    func testSetCustomAdjustmentAmountSetsCustomWithValue() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(7)
        
        XCTAssertEqual(viewModel.counterState.adjustment, .custom)
        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 7)
    }
    
    func testSetCustomAdjustmentAmountCoercesZeroToOne() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(0)
        
        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 1)
    }
    
    func testSetCustomAdjustmentAmountCoercesNegativeToOne() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(-5)
        
        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 1)
    }
    
    // MARK: - increment with custom adjustment
    
    func testIncrementUsesResolvedAdjustmentAmountForTotalStitchesEver() {
        let project = sampleProject(stitchAdjustment: 7, stitchCounterNumber: 0, totalStitchesEver: 100)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.increment()
        
        XCTAssertEqual(viewModel.totalStitchesEver, 107)
    }
    
    func testIncrementWithCustomAdjustmentAddsCorrectAmount() {
        let project = sampleProject(stitchCounterNumber: 0)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(7)
        viewModel.increment()
        
        XCTAssertEqual(viewModel.counterState.count, 7)
    }
    
    // MARK: - loadProject reconstruction
    
    func testLoadProjectReconstructsCustomFromPersistedValueSeven() {
        let project = sampleProject(stitchAdjustment: 7)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.counterState.adjustment, .custom)
        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 7)
    }
    
    func testLoadProjectReconstructsOneFromPersistedValueOne() {
        let project = sampleProject(stitchAdjustment: 1)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.counterState.adjustment, .one)
    }
    
    func testLoadProjectReconstructsFiveFromPersistedValueFive() {
        let project = sampleProject(stitchAdjustment: 5)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.counterState.adjustment, .five)
    }
    
    // MARK: - save persists resolvedAdjustmentAmount
    
    func testSavePersistsResolvedAdjustmentAmountNotEnumRawValue() {
        let project = sampleProject(stitchAdjustment: 1)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(7)
        viewModel.save()
        
        XCTAssertEqual(project.stitchAdjustment, 7)
    }
    
    func testSavePersistsOneWhenAdjustmentIsOne() {
        let project = sampleProject(stitchAdjustment: 7)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.changeAdjustment(.one)
        viewModel.save()
        
        XCTAssertEqual(project.stitchAdjustment, 1)
    }

    func testChangeAdjustmentPreservesCustomAmountWhenSwitchingAwayAndBack() {
        let viewModel = createViewModel()
        viewModel.setCustomAdjustmentAmount(7)
        viewModel.changeAdjustment(.one)
        viewModel.changeAdjustment(.custom)

        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 7)
        XCTAssertEqual(viewModel.counterState.resolvedAdjustmentAmount, 7)
    }

    func testLoadProjectPreserveCounterKeepsInMemoryCustomState() {
        let project = sampleProject(stitchAdjustment: 7, stitchCounterNumber: 10, totalStitchesEver: 50)
        mockService.addProject(project)

        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(11)
        viewModel.increment()

        project.stitchAdjustment = 1
        project.stitchCounterNumber = 1
        project.totalStitchesEver = 1
        viewModel.loadProject(project.id)

        XCTAssertEqual(viewModel.counterState.adjustment, .custom)
        XCTAssertEqual(viewModel.counterState.customAdjustmentAmount, 11)
        XCTAssertEqual(viewModel.counterState.count, 21)
        XCTAssertEqual(viewModel.totalStitchesEver, 61)
    }

    func testSaveCallsProjectServiceWithUpdatedValuesForCustomAmount() {
        let project = sampleProject(stitchAdjustment: 1, stitchCounterNumber: 10, totalStitchesEver: 50)
        mockService.addProject(project)

        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.setCustomAdjustmentAmount(9)
        viewModel.increment()
        viewModel.save()

        XCTAssertEqual(mockService.savedProjects.count, 1)
        XCTAssertEqual(mockService.savedProjects.last?.id, project.id)
        XCTAssertEqual(mockService.savedProjects.last?.stitchCounterNumber, 19)
        XCTAssertEqual(mockService.savedProjects.last?.stitchAdjustment, 9)
        XCTAssertEqual(mockService.savedProjects.last?.totalStitchesEver, 59)
    }
    
    // MARK: - Basic operations
    
    func testLoadProjectPopulatesState() {
        let project = sampleProject()
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        
        XCTAssertEqual(viewModel.projectId, project.id)
        XCTAssertEqual(viewModel.title, "Test Scarf")
        XCTAssertEqual(viewModel.counterState.count, 10)
        XCTAssertEqual(viewModel.totalStitchesEver, 50)
    }
    
    func testLoadProjectWithNilResetsState() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil)
        
        XCTAssertNil(viewModel.projectId)
        XCTAssertEqual(viewModel.counterState.count, 0)
    }
    
    func testIncrementByOneAddsOne() {
        let project = sampleProject(stitchCounterNumber: 10)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.increment()
        
        XCTAssertEqual(viewModel.counterState.count, 11)
        XCTAssertEqual(viewModel.totalStitchesEver, 51)
    }
    
    func testDecrementFloorsAtZero() {
        let project = sampleProject(stitchCounterNumber: 0)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.decrement()
        
        XCTAssertEqual(viewModel.counterState.count, 0)
    }
    
    func testResetCountSetsCountToZero() {
        let project = sampleProject(stitchCounterNumber: 42)
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.resetCount()
        
        XCTAssertEqual(viewModel.counterState.count, 0)
    }
    
    func testChangeAdjustmentUpdatesAdjustment() {
        let viewModel = createViewModel()
        viewModel.changeAdjustment(.five)
        
        XCTAssertEqual(viewModel.counterState.adjustment, .five)
    }
    
    func testResetStateClearsEverything() {
        let project = sampleProject()
        mockService.addProject(project)
        
        let viewModel = createViewModel()
        viewModel.loadProject(project.id)
        viewModel.increment()
        viewModel.resetState()
        
        XCTAssertNil(viewModel.projectId)
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.counterState.count, 0)
        XCTAssertEqual(viewModel.totalStitchesEver, 0)
    }
}
