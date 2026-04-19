import SwiftUI

struct SingleCounterScreen: View {
    @ObservedObject var viewModel: SingleCounterViewModel
    let projectId: UUID?
    let onNavigateToDetail: ((UUID) -> Void)?
    
    @State private var showResetDialog = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.themeColors) private var colors
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isLandscape ? EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24) : EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .onAppear {
            viewModel.loadProject(projectId)
        }
        .resetConfirmationDialog(
            isPresented: $showResetDialog,
            title: "Reset Counter?",
            message: "Are you sure you want to reset the counter to 0?",
            onConfirm: { viewModel.resetCount() }
        )
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            counterTopBar
                .padding(.top, 14)
            CounterView(
                count: viewModel.counterState.count,
                selectedAdjustment: viewModel.counterState.adjustment,
                customAdjustmentAmount: viewModel.counterState.customAdjustmentAmount,
                onIncrement: { viewModel.increment() },
                onDecrement: { viewModel.decrement() },
                onReset: { showResetDialog = true },
                onAdjustmentTapped: { viewModel.changeAdjustment($0) },
                onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount($0) },
                showResetButton: false,
                counterNumberIsVertical: true,
                evenVerticalDistribution: true
            )
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer(minLength: 0)
            BottomActionButtonsView(onResetAll: { showResetDialog = true })
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            counterTopBar
            
            CounterView(
                count: viewModel.counterState.count,
                selectedAdjustment: viewModel.counterState.adjustment,
                customAdjustmentAmount: viewModel.counterState.customAdjustmentAmount,
                onIncrement: { viewModel.increment() },
                onDecrement: { viewModel.decrement() },
                onReset: { showResetDialog = true },
                onAdjustmentTapped: { viewModel.changeAdjustment($0) },
                onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount($0) },
                showResetButton: false,
                counterNumberIsVertical: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            BottomActionButtonsView(onResetAll: { showResetDialog = true })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var counterTopBar: some View {
        HStack {
            if !viewModel.title.isEmpty {
                Text(viewModel.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if let projectId = viewModel.projectId, let onNavigateToDetail = onNavigateToDetail {
                Button {
                    onNavigateToDetail(projectId)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}

#Preview {
    SingleCounterScreen(
        viewModel: SingleCounterViewModel(projectService: ProjectService()),
        projectId: nil,
        onNavigateToDetail: nil
    )
}
