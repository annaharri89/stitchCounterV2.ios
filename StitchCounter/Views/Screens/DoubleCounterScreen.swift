import SwiftUI

struct DoubleCounterScreen: View {
    @ObservedObject var viewModel: DoubleCounterViewModel
    let projectId: UUID?
    let onNavigateToDetail: ((UUID) -> Void)?
    
    @State private var resetDialogType: CounterType?
    @State private var showResetAllDialog = false
    @State private var isShowingCustomAdjustmentTipBanner = false
    @State private var customAdjustmentTipDismissTask: Task<Void, Never>?
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.themeColors) private var colors
    
    private var isWideLayout: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isWideLayout {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(isWideLayout ? EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24) : EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .background(colors.surface)
        .overlay(alignment: .bottom) {
            if isShowingCustomAdjustmentTipBanner {
                Text(String(localized: "tip.customAdjustment"))
                    .font(.subheadline)
                    .foregroundStyle(colors.onSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingCustomAdjustmentTipBanner)
        .onAppear {
            viewModel.loadProject(projectId)
        }
        .onChange(of: projectId) { _, newValue in
            viewModel.loadProject(newValue)
        }
        .onChange(of: viewModel.shouldShowCustomAdjustmentTip) { _, shouldShow in
            guard shouldShow else { return }
            customAdjustmentTipDismissTask?.cancel()
            customAdjustmentTipDismissTask = Task { @MainActor in
                isShowingCustomAdjustmentTipBanner = true
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                isShowingCustomAdjustmentTipBanner = false
                viewModel.onCustomAdjustmentTipShown()
            }
        }
        .alert(resetSingleCounterAlertTitle, isPresented: Binding(
            get: { resetDialogType != nil },
            set: { if !$0 { resetDialogType = nil } }
        )) {
            Button(String(localized: "common.cancel"), role: .cancel) { resetDialogType = nil }
            Button(String(localized: "action_reset"), role: .destructive) {
                if let type = resetDialogType {
                    viewModel.reset(type)
                }
                resetDialogType = nil
            }
        } message: {
            Text(resetSingleCounterAlertMessage)
        }
        .resetConfirmationDialog(
            isPresented: $showResetAllDialog,
            title: String(localized: "doubleCounter.resetAll.title"),
            message: String(localized: "doubleCounter.resetAll.message"),
            onConfirm: { viewModel.resetAll() }
        )
    }
    
    private var resetSingleCounterAlertTitle: String {
        guard let type = resetDialogType else { return "" }
        return String(format: String(localized: "doubleCounter.resetNamed.title"), type.displayName)
    }
    
    private var resetSingleCounterAlertMessage: String {
        guard let type = resetDialogType else { return "" }
        return String(format: String(localized: "doubleCounter.resetNamed.message"), type.displayName)
    }
    
    private func managedCustomAdjustmentDialog(for type: CounterType) -> ManagedCustomAdjustmentDialog {
        ManagedCustomAdjustmentDialog(
            isPresented: viewModel.activeCustomAdjustmentDialogCounterType == type,
            readInput: { viewModel.customAdjustmentDialogInput },
            onDismiss: { viewModel.dismissCustomAdjustmentDialog() },
            onInputChange: { viewModel.updateCustomAdjustmentDialogInput($0) }
        )
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 16) {
            counterTopBar
            
            RowProgressView(
                currentRowCount: viewModel.rowCounterState.count,
                totalRows: viewModel.totalRows
            )
            .frame(maxWidth: .infinity)
            
            CounterView(
                label: String(localized: "counter.type.stitches"),
                count: viewModel.stitchCounterState.count,
                selectedAdjustment: viewModel.stitchCounterState.adjustment,
                customAdjustmentAmount: viewModel.stitchCounterState.customAdjustmentAmount,
                onIncrement: { viewModel.increment(.stitch) },
                onDecrement: { viewModel.decrement(.stitch) },
                onReset: { resetDialogType = .stitch },
                onAdjustmentTapped: { viewModel.changeAdjustment(.stitch, value: $0) },
                onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount(.stitch, value: $0) },
                managedCustomAdjustmentDialog: managedCustomAdjustmentDialog(for: .stitch),
                onManagedCustomAdjustmentEditTap: { viewModel.showCustomAdjustmentDialog(.stitch) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CounterView(
                label: String(localized: "counter.type.rowsRounds"),
                count: viewModel.rowCounterState.count,
                selectedAdjustment: viewModel.rowCounterState.adjustment,
                customAdjustmentAmount: viewModel.rowCounterState.customAdjustmentAmount,
                onIncrement: { viewModel.increment(.row) },
                onDecrement: { viewModel.decrement(.row) },
                onReset: { resetDialogType = .row },
                onAdjustmentTapped: { viewModel.changeAdjustment(.row, value: $0) },
                onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount(.row, value: $0) },
                managedCustomAdjustmentDialog: managedCustomAdjustmentDialog(for: .row),
                onManagedCustomAdjustmentEditTap: { viewModel.showCustomAdjustmentDialog(.row) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            BottomActionButtonsView(
                onResetAll: { showResetAllDialog = true },
                labelText: String(localized: "action.resetAll")
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
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 24) {
                CounterView(
                    label: String(localized: "counter.type.stitches"),
                    count: viewModel.stitchCounterState.count,
                    selectedAdjustment: viewModel.stitchCounterState.adjustment,
                    customAdjustmentAmount: viewModel.stitchCounterState.customAdjustmentAmount,
                    onIncrement: { viewModel.increment(.stitch) },
                    onDecrement: { viewModel.decrement(.stitch) },
                    onReset: { resetDialogType = .stitch },
                    onAdjustmentTapped: { viewModel.changeAdjustment(.stitch, value: $0) },
                    onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount(.stitch, value: $0) },
                    managedCustomAdjustmentDialog: managedCustomAdjustmentDialog(for: .stitch),
                    onManagedCustomAdjustmentEditTap: { viewModel.showCustomAdjustmentDialog(.stitch) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                CounterView(
                    label: String(localized: "counter.type.rowsRounds"),
                    count: viewModel.rowCounterState.count,
                    selectedAdjustment: viewModel.rowCounterState.adjustment,
                    customAdjustmentAmount: viewModel.rowCounterState.customAdjustmentAmount,
                    onIncrement: { viewModel.increment(.row) },
                    onDecrement: { viewModel.decrement(.row) },
                    onReset: { resetDialogType = .row },
                    onAdjustmentTapped: { viewModel.changeAdjustment(.row, value: $0) },
                    onCustomAdjustmentAmountChanged: { viewModel.setCustomAdjustmentAmount(.row, value: $0) },
                    managedCustomAdjustmentDialog: managedCustomAdjustmentDialog(for: .row),
                    onManagedCustomAdjustmentEditTap: { viewModel.showCustomAdjustmentDialog(.row) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            BottomActionButtonsView(
                onResetAll: { showResetAllDialog = true },
                labelText: String(localized: "action.resetAll")
            )
        }
    }
    
    @ViewBuilder
    private var counterTopBar: some View {
        let hasProjectDetailsAction = viewModel.projectId != nil && onNavigateToDetail != nil
        if !viewModel.title.isEmpty || hasProjectDetailsAction {
            HStack(alignment: .center) {
                if !viewModel.title.isEmpty {
                    Text(viewModel.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer(minLength: 0)
                
                if let projectId = viewModel.projectId, let onNavigateToDetail {
                    Button {
                        onNavigateToDetail(projectId)
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(colors.onPrimaryContainer)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(colors.primaryContainer))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "project.details.fabA11y"))
                }
            }
        }
    }
}

#Preview {
    DoubleCounterScreen(
        viewModel: DoubleCounterViewModel(
            projectService: ProjectService(),
            customAdjustmentTipConsumer: NoCustomAdjustmentTipConsumer()
        ),
        projectId: nil,
        onNavigateToDetail: nil
    )
}
