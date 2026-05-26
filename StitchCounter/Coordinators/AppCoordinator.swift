import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var currentTab: TabItem = .library
    @Published var showingSheet: SheetDestination?
    
    let projectService: ProjectService
    let themeService: ThemeService
    private let logger: FileLogging
    private var cancellables = Set<AnyCancellable>()
    
    lazy var libraryViewModel: LibraryViewModel = {
        LibraryViewModel(projectService: projectService)
    }()
    
    lazy var settingsViewModel: SettingsViewModel = {
        SettingsViewModel(themeService: themeService, projectService: projectService)
    }()
    
    init(logger: FileLogging = FileLogger.shared) {
        self.logger = logger
        self.projectService = ProjectService()
        self.themeService = ThemeService()
        logger.initializeLogging()
        logger.info(tag: "AppCoordinator", message: "Application coordinator initialized", metadata: nil)
        
        themeService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func createProjectDetailViewModel() -> ProjectDetailViewModel {
        ProjectDetailViewModel(projectService: projectService)
    }
    
    func sheetDestination(for project: Project?, type projectType: ProjectType, id projectId: UUID) -> SheetDestination {
        let resolvedProjectType = project?.type ?? projectType
        let resolvedProjectId = project?.id ?? projectId
        switch resolvedProjectType {
        case .single:
            return .singleCounter(projectId: resolvedProjectId)
        case .double:
            return .doubleCounter(projectId: resolvedProjectId)
        }
    }
    
    func showCounter(for project: Project) {
        showingSheet = sheetDestination(for: project, type: project.type, id: project.id)
    }
    
    func showProjectDetail(projectId: UUID) {
        showingSheet = .projectDetail(projectId: projectId)
    }
    
    func dismissSheet() {
        showingSheet = nil
    }
    
    func navigateToCounterAfterCreation(projectId: UUID, projectType: ProjectType) {
        showingSheet = sheetDestination(for: nil, type: projectType, id: projectId)
    }
}

enum TabItem: String, CaseIterable {
    case library
    case stats
    case settings
    
    var title: String {
        switch self {
        case .library: return String(localized: "nav.library")
        case .stats: return String(localized: "nav.stats")
        case .settings: return String(localized: "nav.settings")
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "list.bullet"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}
