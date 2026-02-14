import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var currentTab: TabItem = .library
    @Published var showingSheet: SheetDestination?
    
    let projectService: ProjectService
    let themeService: ThemeService
    
    lazy var libraryViewModel: LibraryViewModel = {
        LibraryViewModel(projectService: projectService)
    }()
    
    lazy var settingsViewModel: SettingsViewModel = {
        SettingsViewModel(themeService: themeService, projectService: projectService)
    }()
    
    init() {
        self.projectService = ProjectService()
        self.themeService = ThemeService()
    }
    
    func createSingleCounterViewModel() -> SingleCounterViewModel {
        SingleCounterViewModel(projectService: projectService)
    }
    
    func createDoubleCounterViewModel() -> DoubleCounterViewModel {
        DoubleCounterViewModel(projectService: projectService)
    }
    
    func createProjectDetailViewModel() -> ProjectDetailViewModel {
        ProjectDetailViewModel(projectService: projectService)
    }
    
    func showCounter(for project: Project) {
        switch project.type {
        case .single:
            showingSheet = .singleCounter(projectId: project.id)
        case .double:
            showingSheet = .doubleCounter(projectId: project.id)
        }
    }
    
    func showProjectDetail(projectId: UUID) {
        showingSheet = .projectDetail(projectId: projectId)
    }
    
    func dismissSheet() {
        showingSheet = nil
    }
    
    func navigateToCounterAfterCreation(projectId: UUID, projectType: ProjectType) {
        switch projectType {
        case .single:
            showingSheet = .singleCounter(projectId: projectId)
        case .double:
            showingSheet = .doubleCounter(projectId: projectId)
        }
    }
}

enum TabItem: String, CaseIterable {
    case library
    case settings
    
    var title: String {
        switch self {
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}
