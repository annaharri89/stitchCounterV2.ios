import SwiftUI

struct CounterView: View {
    let label: String?
    let count: Int
    let selectedAdjustment: AdjustmentAmount
    let customAdjustmentAmount: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onReset: () -> Void
    let onAdjustmentTapped: (AdjustmentAmount) -> Void
    let onCustomAdjustmentAmountChanged: (Int) -> Void
    let managedCustomAdjustmentDialog: ManagedCustomAdjustmentDialog?
    let onManagedCustomAdjustmentEditTap: (() -> Void)?
    let showResetButton: Bool
    let counterNumberIsVertical: Bool
    let evenVerticalDistribution: Bool
    
    @Environment(\.themeColors) private var colors
    
    init(
        label: String? = nil,
        count: Int,
        selectedAdjustment: AdjustmentAmount,
        customAdjustmentAmount: Int = AdjustmentAmount.custom.defaultAmount,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onAdjustmentTapped: @escaping (AdjustmentAmount) -> Void,
        onCustomAdjustmentAmountChanged: @escaping (Int) -> Void = { _ in },
        managedCustomAdjustmentDialog: ManagedCustomAdjustmentDialog? = nil,
        onManagedCustomAdjustmentEditTap: (() -> Void)? = nil,
        showResetButton: Bool = true,
        counterNumberIsVertical: Bool = false,
        evenVerticalDistribution: Bool = false
    ) {
        self.label = label
        self.count = count
        self.selectedAdjustment = selectedAdjustment
        self.customAdjustmentAmount = customAdjustmentAmount
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onReset = onReset
        self.onAdjustmentTapped = onAdjustmentTapped
        self.onCustomAdjustmentAmountChanged = onCustomAdjustmentAmountChanged
        self.managedCustomAdjustmentDialog = managedCustomAdjustmentDialog
        self.onManagedCustomAdjustmentEditTap = onManagedCustomAdjustmentEditTap
        self.showResetButton = showResetButton
        self.counterNumberIsVertical = counterNumberIsVertical
        self.evenVerticalDistribution = evenVerticalDistribution
    }
    
    private var adjustmentControlsRow: some View {
        HStack {
            if showResetButton {
                Button {
                    onReset()
                } label: {
                    Text("action_reset")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(colors.quaternary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            AdjustmentButtonsView(
                selectedAdjustment: selectedAdjustment,
                customAdjustmentAmount: customAdjustmentAmount,
                onAdjustmentTapped: onAdjustmentTapped,
                onCustomAdjustmentAmountChanged: onCustomAdjustmentAmountChanged,
                managedCustomAdjustmentDialog: managedCustomAdjustmentDialog,
                onManagedCustomAdjustmentEditTap: onManagedCustomAdjustmentEditTap
            )
            .frame(maxWidth: .infinity)
        }
    }
    
    var body: some View {
        VStack(spacing: counterNumberIsVertical && evenVerticalDistribution ? 0 : 12) {
            if let label = label {
                Text(label)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if counterNumberIsVertical {
                if evenVerticalDistribution {
                    verticalEvenPortraitColumn
                } else {
                    verticalCounterAndButtonsRegion
                }
            } else {
                horizontalCounterAndButtonsRegion
            }
            
            if !(counterNumberIsVertical && evenVerticalDistribution) {
                adjustmentControlsRow
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: counterNumberIsVertical && evenVerticalDistribution ? .center : .top
        )
    }
    
    private var verticalEvenPortraitColumn: some View {
        GeometryReader { geometry in
            let gapBetweenCounterAndButtons: CGFloat = 28
            let buttonSpacing: CGFloat = 24
            let totalHeight = geometry.size.height
            let totalWidth = geometry.size.width
            let available = max(0, totalHeight - gapBetweenCounterAndButtons)
            let singleButtonMaxSide = max(0, (totalWidth - buttonSpacing) / 2)
            let maxSquareButtonStripHeight = min(available, singleButtonMaxSide)
            let minimumCounterHeight: CGFloat = 96
            let counterWouldBeTooShort = available - maxSquareButtonStripHeight < minimumCounterHeight
            let buttonStripHeight = counterWouldBeTooShort
                ? max(56, available - minimumCounterHeight)
                : maxSquareButtonStripHeight
            let counterHeight = available - buttonStripHeight
            let counterDisplayFrameHeight = min(
                counterHeight,
                max(120, totalWidth * 0.48 + 32)
            )
            VStack(spacing: 0) {
                VStack(spacing: gapBetweenCounterAndButtons) {
                    CounterDisplayView(
                        count: count,
                        isVertical: true,
                        verticalContentAlignment: .bottom
                    )
                    .frame(height: counterDisplayFrameHeight, alignment: .bottom)
                    IncreaseDecreaseButtonsView(
                        onIncrement: onIncrement,
                        onDecrement: onDecrement
                    )
                    .frame(height: buttonStripHeight)
                    .frame(maxWidth: .infinity)
                }
                Spacer(minLength: 0)
                adjustmentControlsRow
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var verticalCounterAndButtonsRegion: some View {
        GeometryReader { geometry in
            let verticalGap: CGFloat = 12
            let buttonSpacing: CGFloat = 24
            let totalHeight = geometry.size.height
            let available = max(0, totalHeight - verticalGap)
            let singleButtonMaxSide = max(0, (geometry.size.width - buttonSpacing) / 2)
            let maxSquareButtonStripHeight = min(available, singleButtonMaxSide)
            let minimumCounterHeight: CGFloat = 96
            let counterWouldBeTooShort = available - maxSquareButtonStripHeight < minimumCounterHeight
            let buttonStripHeight = counterWouldBeTooShort
                ? max(56, available - minimumCounterHeight)
                : maxSquareButtonStripHeight
            let counterHeight = available - buttonStripHeight
            VStack(spacing: verticalGap) {
                CounterDisplayView(count: count, isVertical: true)
                    .frame(height: counterHeight)
                IncreaseDecreaseButtonsView(
                    onIncrement: onIncrement,
                    onDecrement: onDecrement
                )
                .frame(height: buttonStripHeight)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var horizontalCounterAndButtonsRegion: some View {
        GeometryReader { geometry in
            let horizontalGap: CGFloat = 16
            let textTrailingPadding: CGFloat = 24
            let innerWidth = geometry.size.width - horizontalGap
            let counterColumnWidth = innerWidth / 3
            let buttonsColumnWidth = innerWidth * 2 / 3
            let counterTextWidth = max(56, counterColumnWidth - textTrailingPadding)
            HStack(spacing: horizontalGap) {
                CounterDisplayView(count: count)
                    .frame(width: counterTextWidth, height: geometry.size.height)
                    .padding(.trailing, textTrailingPadding)
                IncreaseDecreaseButtonsView(
                    onIncrement: onIncrement,
                    onDecrement: onDecrement
                )
                .frame(width: buttonsColumnWidth, height: geometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CounterView(
        label: "Stitches",
        count: 42,
        selectedAdjustment: .five,
        customAdjustmentAmount: 10,
        onIncrement: {},
        onDecrement: {},
        onReset: {},
        onAdjustmentTapped: { _ in },
        onCustomAdjustmentAmountChanged: { _ in }
    )
    .padding()
}
