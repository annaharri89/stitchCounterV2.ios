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
                adjustmentButton(for: amount)
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
    
    @ViewBuilder
    private func adjustmentButton(for amount: AdjustmentAmount) -> some View {
        let isSelected = amount == selectedAdjustment
        
        Button {
            onAdjustmentTapped(amount)
        } label: {
            HStack(spacing: 4) {
                Text(amount.displayText(customAmount: resolvedCustomAmount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if amount == .custom {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? colors.secondary : colors.tertiary)
            .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
            .cornerRadius(8)
        }
        .accessibilityLabel(
            amount == .custom
                ? "Custom +\(resolvedCustomAmount)"
                : amount.displayText
        )
        .accessibilityHint(
            amount == .custom
                ? "Long press to change custom amount"
                : ""
        )
        .if(amount == .custom) { view in
            view.contextMenu {
                Button {
                    customAdjustmentInput = "\(resolvedCustomAmount)"
                    showCustomAdjustmentAlert = true
                } label: {
                    Label("Edit Custom Amount", systemImage: "pencil")
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
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
