import SwiftUI

struct AdjustmentButtonsView: View {
    let selectedAdjustment: AdjustmentAmount
    let customAdjustmentAmount: Int
    let onAdjustmentTapped: (AdjustmentAmount) -> Void
    let onCustomAdjustmentAmountChanged: (Int) -> Void
    
    @State private var showCustomAdjustmentAlert = false
    @State private var customAdjustmentInput = ""
    @Environment(\.themeColors) private var colors
    
    private var resolvedCustomAmount: Int {
        max(customAdjustmentAmount, 1)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AdjustmentAmount.allCases) { amount in
                if amount == .custom {
                    customAdjustmentButton
                } else {
                    adjustmentButton(for: amount)
                }
            }
        }
        .alert(
            "Set Custom Amount",
            isPresented: $showCustomAdjustmentAlert
        ) {
            TextField("Enter amount", text: $customAdjustmentInput)
                .keyboardType(.numberPad)
                .accessibilityLabel("Custom adjustment amount")
            
            Button("Save") {
                if let parsed = Int(customAdjustmentInput), parsed > 0 {
                    onCustomAdjustmentAmountChanged(parsed)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a custom adjustment amount")
        }
    }
    
    private func adjustmentButton(for amount: AdjustmentAmount) -> some View {
        let isSelected = amount == selectedAdjustment
        
        return Button {
            onAdjustmentTapped(amount)
        } label: {
            Text(amount.displayText(customAmount: resolvedCustomAmount))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minWidth: 44, minHeight: 44)
                .background(isSelected ? colors.secondary : colors.tertiary)
                .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
                .cornerRadius(8)
        }
        .accessibilityLabel(
            amount == .custom
                ? "Custom +\(resolvedCustomAmount)"
                : amount.displayText
        )
    }
    
    private var customAdjustmentButton: some View {
        let isSelected = selectedAdjustment == .custom
        
        return HStack(spacing: 6) {
            Text(AdjustmentAmount.custom.displayText(customAmount: resolvedCustomAmount))
                .font(.subheadline)
                .fontWeight(.medium)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    onAdjustmentTapped(.custom)
                }
            
            Image(systemName: "pencil")
                .font(.caption)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .onTapGesture {
                    customAdjustmentInput = "\(resolvedCustomAmount)"
                    showCustomAdjustmentAlert = true
                }
                .accessibilityElement()
                .accessibilityLabel("Edit custom adjustment amount")
                .accessibilityHint("Opens a dialog to enter a custom number")
                .accessibilityAddTraits(.isButton)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(isSelected ? colors.secondary : colors.tertiary)
        .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
        .cornerRadius(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom +\(resolvedCustomAmount)")
        .accessibilityHint("Tap amount to select custom adjustment")
    }
}

#Preview {
    AdjustmentButtonsView(
        selectedAdjustment: .custom,
        customAdjustmentAmount: 10,
        onAdjustmentTapped: { _ in },
        onCustomAdjustmentAmountChanged: { _ in }
    )
}
