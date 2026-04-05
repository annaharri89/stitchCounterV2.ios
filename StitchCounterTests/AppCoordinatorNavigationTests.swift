import XCTest
@testable import StitchCounter

@MainActor
final class AppCoordinatorNavigationTests: XCTestCase {

    func testNavigateToCounterAfterCreation_single_setsSingleCounterSheet() {
        let coordinator = AppCoordinator()
        let id = UUID()
        coordinator.navigateToCounterAfterCreation(projectId: id, projectType: .single)
        guard case let .singleCounter(projectId) = coordinator.showingSheet else {
            return XCTFail("Expected singleCounter sheet")
        }
        XCTAssertEqual(projectId, id)
    }

    func testNavigateToCounterAfterCreation_double_setsDoubleCounterSheet() {
        let coordinator = AppCoordinator()
        let id = UUID()
        coordinator.navigateToCounterAfterCreation(projectId: id, projectType: .double)
        guard case let .doubleCounter(projectId) = coordinator.showingSheet else {
            return XCTFail("Expected doubleCounter sheet")
        }
        XCTAssertEqual(projectId, id)
    }
}
