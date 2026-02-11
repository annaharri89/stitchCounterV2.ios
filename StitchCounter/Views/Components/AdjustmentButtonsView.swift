import SwiftUI

struct AdjustmentButtonsView: View {
    let selectedAdjustment: AdjustmentAmount
    let onAdjustmentTapped: (AdjustmentAmount) -> Void
    
    @Environment(\.themeColors) private var colors
    
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
                        .background(isSelected ? colors.secondary : colors.tertiary)
                        .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
                        .cornerRadius(8)
                }
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
