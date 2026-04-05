import XCTest
@testable import StitchCounter

@MainActor
final class ProjectDetailViewModelTests: XCTestCase {
    
    private var mockService: MockProjectService!
    
    override func setUp() {
        super.setUp()
        mockService = MockProjectService()
    }
    
    private func createViewModel() -> ProjectDetailViewModel {
        ProjectDetailViewModel(projectService: mockService)
    }
    
    func testAttemptDismissalWhenDraftValidCreatesProjectAndAllowsDismissal() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil, projectType: .single)
        viewModel.updateTitle("  My scarf  ")
        
        viewModel.attemptDismissal()
        
        XCTAssertEqual(viewModel.dismissalResult, .allowed)
        XCTAssertTrue(viewModel.isProjectPersistedInLibrary)
        XCTAssertEqual(viewModel.title, "  My scarf  ")
    }
    
    func testAttemptDismissalWhenDraftTitleEmptyShowsDiscardDialog() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil, projectType: .single)
        viewModel.updateTitle("")
        
        viewModel.attemptDismissal()
        
        XCTAssertEqual(viewModel.dismissalResult, .showDiscardDialog)
        XCTAssertNotNil(viewModel.titleError)
    }
    
    func testAttemptDismissalWhenDoubleDraftMissingTotalRowsShowsDiscardDialog() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil, projectType: .double)
        viewModel.updateTitle("Blanket")
        viewModel.updateTotalRows("")
        
        viewModel.attemptDismissal()
        
        XCTAssertEqual(viewModel.dismissalResult, .showDiscardDialog)
        XCTAssertNotNil(viewModel.totalRowsError)
    }
    
    func testAttemptDismissalWhenPersistedSavesAndAllowsDismissal() {
        let viewModel = createViewModel()
        let existing = Project(type: .single, title: "Old")
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        viewModel.updateTitle("Updated title")
        
        viewModel.attemptDismissal()
        
        XCTAssertEqual(viewModel.dismissalResult, .allowed)
        let stored = mockService.getProject(by: existing.id)
        XCTAssertEqual(stored?.title, "Updated title")
    }
    
    func testSaveWhenPersistedSkipsWhenTitleWouldBeInvalid() {
        let viewModel = createViewModel()
        let existing = Project(type: .single, title: "Ok")
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        viewModel.updateTitle("   ")
        
        let saved = viewModel.save()
        
        XCTAssertFalse(saved)
    }
    
    func testCreateProjectWhenDoubleRequiresPositiveTotalRows() {
        let viewModel = createViewModel()
        viewModel.loadProject(nil, projectType: .double)
        viewModel.updateTitle("Shawl")
        viewModel.updateTotalRows("0")
        
        let newId = viewModel.createProject()
        
        XCTAssertNil(newId)
        XCTAssertNotNil(viewModel.totalRowsError)
    }
}
