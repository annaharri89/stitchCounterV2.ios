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
    let showResetButton: Bool
    let counterNumberIsVertical: Bool
    
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
        showResetButton: Bool = true,
        counterNumberIsVertical: Bool = false
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
        self.showResetButton = showResetButton
        self.counterNumberIsVertical = counterNumberIsVertical
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let label = label {
                Text(label)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if counterNumberIsVertical {
                CounterDisplayView(count: count, isVertical: true)
            }
            
            HStack(spacing: 16) {
                if !counterNumberIsVertical {
                    CounterDisplayView(count: count)
                        .frame(maxWidth: .infinity)
                }
                
                IncreaseDecreaseButtonsView(
                    onIncrement: onIncrement,
                    onDecrement: onDecrement
                )
                .frame(maxWidth: counterNumberIsVertical ? .infinity : nil)
            }
            
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
                            .background(colors.quaternary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                AdjustmentButtonsView(
                    selectedAdjustment: selectedAdjustment,
                    customAdjustmentAmount: customAdjustmentAmount,
                    onAdjustmentTapped: onAdjustmentTapped,
                    onCustomAdjustmentAmountChanged: onCustomAdjustmentAmountChanged
                )
            }
        }
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
