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

    func testShowCounter_single_setsSingleCounterSheetMatchingProjectId() {
        let coordinator = AppCoordinator()
        let project = Project(type: .single)
        coordinator.showCounter(for: project)
        guard case let .singleCounter(projectId) = coordinator.showingSheet else {
            return XCTFail("Expected singleCounter sheet")
        }
        XCTAssertEqual(projectId, project.id)
    }

    func testShowCounter_double_setsDoubleCounterSheetMatchingProjectId() {
        let coordinator = AppCoordinator()
        let project = Project(type: .double)
        coordinator.showCounter(for: project)
        guard case let .doubleCounter(projectId) = coordinator.showingSheet else {
            return XCTFail("Expected doubleCounter sheet")
        }
        XCTAssertEqual(projectId, project.id)
    }

    func testSheetDestination_nonNilProject_usesProjectTypeAndIdOverFallbackArguments() {
        let coordinator = AppCoordinator()
        let project = Project(type: .single)
        let fallbackProjectId = UUID()
        let destination = coordinator.sheetDestination(
            for: project,
            type: .double,
            id: fallbackProjectId
        )
        guard case let .singleCounter(resolvedProjectId) = destination else {
            return XCTFail("Expected singleCounter from project's type")
        }
        XCTAssertEqual(resolvedProjectId, project.id)
        XCTAssertNotEqual(resolvedProjectId, fallbackProjectId)
    }

    func testSheetDestination_nilProject_usesProvidedTypeAndId() {
        let coordinator = AppCoordinator()
        let projectId = UUID()
        let singleDestination = coordinator.sheetDestination(for: nil, type: .single, id: projectId)
        guard case let .singleCounter(singleResolvedId) = singleDestination else {
            return XCTFail("Expected singleCounter")
        }
        XCTAssertEqual(singleResolvedId, projectId)

        let doubleDestination = coordinator.sheetDestination(for: nil, type: .double, id: projectId)
        guard case let .doubleCounter(doubleResolvedId) = doubleDestination else {
            return XCTFail("Expected doubleCounter")
        }
        XCTAssertEqual(doubleResolvedId, projectId)
    }
}
