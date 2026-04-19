import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let themeColors = coordinator.themeService.colors(for: colorScheme)

        TabView(selection: $coordinator.currentTab) {
            LibraryScreen(
                viewModel: coordinator.libraryViewModel,
                showingSheet: $coordinator.showingSheet
            )
            .tabItem {
                Label(TabItem.library.title, systemImage: TabItem.library.icon)
            }
            .tag(TabItem.library)

            StatsScreen()
                .tabItem {
                    Label(TabItem.stats.title, systemImage: TabItem.stats.icon)
                }
                .tag(TabItem.stats)

            SettingsScreen(viewModel: coordinator.settingsViewModel)
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
                }
                .tag(TabItem.settings)
        }
        .tint(themeColors.primary)
        .themeColors(themeColors)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                coordinator.themeService.applyPendingAlternateIconIfNeeded()
            }
        }
        .sheet(item: $coordinator.showingSheet) { destination in
            sheetContent(for: destination)
                .themeColors(themeColors)
        }
        .environmentObject(coordinator)
    }
    
    @ViewBuilder
    private func sheetContent(for destination: SheetDestination) -> some View {
        switch destination {
        case .singleCounter(let projectId):
            SingleCounterSheetHost(projectId: projectId, projectService: coordinator.projectService)
                .environmentObject(coordinator)
                .id(SheetDestination.singleCounter(projectId: projectId).id)
        case .doubleCounter(let projectId):
            DoubleCounterSheetHost(projectId: projectId, projectService: coordinator.projectService)
                .environmentObject(coordinator)
                .id(SheetDestination.doubleCounter(projectId: projectId).id)
            
        case .newProjectDetail(let projectType):
            let viewModel = coordinator.createProjectDetailViewModel()
            ProjectDetailScreen(
                viewModel: viewModel,
                projectId: nil,
                projectType: projectType,
                onDismiss: {
                    coordinator.dismissSheet()
                    coordinator.libraryViewModel.refreshProjects()
                },
                onProjectCreated: { projectId in
                    coordinator.navigateToCounterAfterCreation(projectId: projectId, projectType: projectType)
                    coordinator.libraryViewModel.refreshProjects()
                }
            )
            
        case .projectDetail(let projectId):
            let viewModel = coordinator.createProjectDetailViewModel()
            ProjectDetailScreen(
                viewModel: viewModel,
                projectId: projectId,
                projectType: nil,
                onDismiss: {
                    coordinator.dismissSheet()
                    coordinator.libraryViewModel.refreshProjects()
                },
                onNavigateBack: { id in
                    if let project = coordinator.projectService.getProject(by: id) {
                        coordinator.showCounter(for: project)
                    }
                }
            )
        }
    }
}

struct SingleCounterSheetHost: View {
    let projectId: UUID
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: SingleCounterViewModel

    init(projectId: UUID, projectService: ProjectServiceProtocol) {
        self.projectId = projectId
        _viewModel = StateObject(wrappedValue: SingleCounterViewModel(projectService: projectService))
    }

    var body: some View {
        SingleCounterScreen(
            viewModel: viewModel,
            projectId: projectId,
            onNavigateToDetail: { id in
                coordinator.showingSheet = .projectDetail(projectId: id)
            }
        )
        .onDisappear {
            viewModel.attemptDismissal()
        }
    }
}

struct DoubleCounterSheetHost: View {
    let projectId: UUID
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: DoubleCounterViewModel

    init(projectId: UUID, projectService: ProjectServiceProtocol) {
        self.projectId = projectId
        _viewModel = StateObject(wrappedValue: DoubleCounterViewModel(projectService: projectService))
    }

    var body: some View {
        DoubleCounterScreen(
            viewModel: viewModel,
            projectId: projectId,
            onNavigateToDetail: { id in
                coordinator.showingSheet = .projectDetail(projectId: id)
            }
        )
        .onDisappear {
            viewModel.attemptDismissal()
        }
    }
}

#Preview {
    ContentView()
}
