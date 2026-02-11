import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let themeColors = coordinator.themeService.colors(for: colorScheme)
        
        TabView(selection: $coordinator.currentTab) {
            HomeScreen(showingSheet: $coordinator.showingSheet)
                .tabItem {
                    Label(TabItem.home.title, systemImage: TabItem.home.icon)
                }
                .tag(TabItem.home)
            
            LibraryScreen(
                viewModel: coordinator.libraryViewModel,
                showingSheet: $coordinator.showingSheet
            )
            .tabItem {
                Label(TabItem.library.title, systemImage: TabItem.library.icon)
            }
            .tag(TabItem.library)
            
            SettingsScreen(viewModel: coordinator.settingsViewModel)
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
                }
                .tag(TabItem.settings)
        }
        .tint(themeColors.primary)
        .themeColors(themeColors)
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
            let viewModel = coordinator.createSingleCounterViewModel()
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
            
        case .doubleCounter(let projectId):
            let viewModel = coordinator.createDoubleCounterViewModel()
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
            
        case .newProjectDetail(let projectType):
            let viewModel = coordinator.createProjectDetailViewModel()
            ProjectDetailScreen(
                viewModel: viewModel,
                projectId: nil,
                projectType: projectType,
                onDismiss: {
                    coordinator.dismissSheet()
                },
                onProjectCreated: { newProjectId in
                    coordinator.navigateToCounterAfterCreation(projectId: newProjectId, projectType: projectType)
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

#Preview {
    ContentView()
}
