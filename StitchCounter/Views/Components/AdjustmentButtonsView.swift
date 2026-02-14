import SwiftUI

struct AdjustmentButtonsView: View {
    let selectedAdjustment: AdjustmentAmount
    let onAdjustmentTapped: (AdjustmentAmount) -> Void

    @Environment(\.themeColors) private var colors
    @Environment(\.themeStyle) private var style

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AdjustmentAmount.allCases) { amount in
                let isSelected = amount == selectedAdjustment
                Button {
                    onAdjustmentTapped(amount)
                } label: {
                    Text(amount.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .themedButtonBackground(
                            containerColor: isSelected ? colors.secondary : colors.tertiary,
                            contentColor: isSelected ? colors.onSecondary : colors.onTertiary
                        )
                }
                .accessibilityLabel("Adjust by \(amount.displayText)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    AdjustmentButtonsView(
        selectedAdjustment: .one,
        onAdjustmentTapped: { _ in }
    )
}
