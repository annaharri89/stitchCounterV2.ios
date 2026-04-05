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
    
    func testReorderImagePathsMovesDraggedItemBeforeDropTargetIndex() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "With photos",
            imagePaths: ["a.jpg", "b.jpg", "c.jpg", "d.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.reorderImagePaths(draggedPath: "a.jpg", dropTargetPath: "c.jpg")
        
        XCTAssertEqual(viewModel.imagePaths, ["b.jpg", "c.jpg", "a.jpg", "d.jpg"])
    }
    
    func testReorderImagePathsMovesItemToStart() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "With photos",
            imagePaths: ["a.jpg", "b.jpg", "c.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.reorderImagePaths(draggedPath: "c.jpg", dropTargetPath: "a.jpg")
        
        XCTAssertEqual(viewModel.imagePaths, ["c.jpg", "a.jpg", "b.jpg"])
    }
    
    func testReorderImagePathsNoOpWhenPathsAreSameOrUnknown() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "With photos",
            imagePaths: ["a.jpg", "b.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.reorderImagePaths(draggedPath: "a.jpg", dropTargetPath: "a.jpg")
        XCTAssertEqual(viewModel.imagePaths, ["a.jpg", "b.jpg"])
        
        viewModel.reorderImagePaths(draggedPath: "missing.jpg", dropTargetPath: "a.jpg")
        XCTAssertEqual(viewModel.imagePaths, ["a.jpg", "b.jpg"])
    }
    
    func testApplyImagePathsOrderUpdatesWhenValidPermutation() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "Photos",
            imagePaths: ["x.jpg", "y.jpg", "z.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.applyImagePathsOrder(["z.jpg", "x.jpg", "y.jpg"])
        
        XCTAssertEqual(viewModel.imagePaths, ["z.jpg", "x.jpg", "y.jpg"])
    }
    
    func testApplyImagePathsOrderRejectedWhenCountMismatches() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "Photos",
            imagePaths: ["a.jpg", "b.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.applyImagePathsOrder(["a.jpg"])
        
        XCTAssertEqual(viewModel.imagePaths, ["a.jpg", "b.jpg"])
    }
    
    func testApplyImagePathsOrderRejectedWhenNotPermutation() {
        let viewModel = createViewModel()
        let existing = Project(
            type: .single,
            title: "Photos",
            imagePaths: ["a.jpg", "b.jpg"]
        )
        mockService.addProject(existing)
        viewModel.loadProjectById(existing.id)
        
        viewModel.applyImagePathsOrder(["a.jpg", "c.jpg"])
        
        XCTAssertEqual(viewModel.imagePaths, ["a.jpg", "b.jpg"])
    }
}
