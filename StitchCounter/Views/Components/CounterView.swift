import SwiftUI

struct CounterView: View {
    let label: String?
    let count: Int
    let selectedAdjustment: AdjustmentAmount
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onReset: () -> Void
    let onAdjustmentTapped: (AdjustmentAmount) -> Void
    let showResetButton: Bool
    let counterNumberIsVertical: Bool

    @Environment(\.themeColors) private var colors
    @Environment(\.themeStyle) private var style

    init(
        label: String? = nil,
        count: Int,
        selectedAdjustment: AdjustmentAmount,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onAdjustmentTapped: @escaping (AdjustmentAmount) -> Void,
        showResetButton: Bool = true,
        counterNumberIsVertical: Bool = false
    ) {
        self.label = label
        self.count = count
        self.selectedAdjustment = selectedAdjustment
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onReset = onReset
        self.onAdjustmentTapped = onAdjustmentTapped
        self.showResetButton = showResetButton
        self.counterNumberIsVertical = counterNumberIsVertical
    }

    var body: some View {
        VStack(spacing: 12) {
            if let label = label {
                Text(label)
                    .font(.system(.headline, design: style.headingFontDesign))
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
                        Text("Reset")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .themedButtonBackground(
                                containerColor: colors.quaternary,
                                contentColor: .white
                            )
                    }
                    .accessibilityLabel("Reset counter")
                    .accessibilityHint("Resets this counter to zero")
                }

                Spacer()

                AdjustmentButtonsView(
                    selectedAdjustment: selectedAdjustment,
                    onAdjustmentTapped: onAdjustmentTapped
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
        onIncrement: {},
        onDecrement: {},
        onReset: {},
        onAdjustmentTapped: { _ in }
    )
    .padding()
}
