import SwiftUI

struct DoubleCounterScreen: View {
    @ObservedObject var viewModel: DoubleCounterViewModel
    let projectId: UUID?
    let onNavigateToDetail: ((UUID) -> Void)?
    
    @State private var resetDialogType: CounterType?
    @State private var showResetAllDialog = false
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
        .padding(isLandscape ? EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24) : EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .onAppear {
            viewModel.loadProject(projectId)
        }
        .alert("Reset \(resetDialogType?.displayName ?? "") Counter?", isPresented: Binding(
            get: { resetDialogType != nil },
            set: { if !$0 { resetDialogType = nil } }
        )) {
            Button("Cancel", role: .cancel) { resetDialogType = nil }
            Button("Reset", role: .destructive) {
                if let type = resetDialogType {
                    viewModel.reset(type)
                }
                resetDialogType = nil
            }
        } message: {
            Text("Are you sure you want to reset the \(resetDialogType?.displayName ?? "") counter to 0?")
        }
        .resetConfirmationDialog(
            isPresented: $showResetAllDialog,
            title: "Reset All Counters?",
            message: "Are you sure you want to reset both Stitches and Rows/Rounds counters to 0?",
            onConfirm: { viewModel.resetAll() }
        )
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 16) {
            counterTopBar
            
            RowProgressView(
                currentRowCount: viewModel.rowCounterState.count,
                totalRows: viewModel.totalRows
            )
            
            CounterView(
                label: "Stitches",
                count: viewModel.stitchCounterState.count,
                selectedAdjustment: viewModel.stitchCounterState.adjustment,
                onIncrement: { viewModel.increment(.stitch) },
                onDecrement: { viewModel.decrement(.stitch) },
                onReset: { resetDialogType = .stitch },
                onAdjustmentTapped: { viewModel.changeAdjustment(.stitch, value: $0) }
            )
            
            CounterView(
                label: "Rows/Rounds",
                count: viewModel.rowCounterState.count,
                selectedAdjustment: viewModel.rowCounterState.adjustment,
                onIncrement: { viewModel.increment(.row) },
                onDecrement: { viewModel.decrement(.row) },
                onReset: { resetDialogType = .row },
                onAdjustmentTapped: { viewModel.changeAdjustment(.row, value: $0) }
            )
            
            Spacer()
            
            BottomActionButtonsView(
                onResetAll: { showResetAllDialog = true },
                labelText: "Reset All"
            )
        }
    }
    
    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            counterTopBar
            
            RowProgressView(
                currentRowCount: viewModel.rowCounterState.count,
                totalRows: viewModel.totalRows
            )
            
            HStack(spacing: 24) {
                CounterView(
                    label: "Stitches",
                    count: viewModel.stitchCounterState.count,
                    selectedAdjustment: viewModel.stitchCounterState.adjustment,
                    onIncrement: { viewModel.increment(.stitch) },
                    onDecrement: { viewModel.decrement(.stitch) },
                    onReset: { resetDialogType = .stitch },
                    onAdjustmentTapped: { viewModel.changeAdjustment(.stitch, value: $0) }
                )
                
                CounterView(
                    label: "Rows/Rounds",
                    count: viewModel.rowCounterState.count,
                    selectedAdjustment: viewModel.rowCounterState.adjustment,
                    onIncrement: { viewModel.increment(.row) },
                    onDecrement: { viewModel.decrement(.row) },
                    onReset: { resetDialogType = .row },
                    onAdjustmentTapped: { viewModel.changeAdjustment(.row, value: $0) }
                )
            }
            
            BottomActionButtonsView(
                onResetAll: { showResetAllDialog = true },
                labelText: "Reset All"
            )
        }
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
    DoubleCounterScreen(
        viewModel: DoubleCounterViewModel(projectService: ProjectService()),
        projectId: nil,
        onNavigateToDetail: nil
    )
}
