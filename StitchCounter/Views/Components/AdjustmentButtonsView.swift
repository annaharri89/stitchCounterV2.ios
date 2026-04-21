import SwiftUI

struct ManagedCustomAdjustmentDialog {
    let isPresented: Bool
    let readInput: () -> String
    let onDismiss: () -> Void
    let onInputChange: (String) -> Void
}

struct AdjustmentButtonsView: View {
    let selectedAdjustment: AdjustmentAmount
    let customAdjustmentAmount: Int
    let onAdjustmentTapped: (AdjustmentAmount) -> Void
    let onCustomAdjustmentAmountChanged: (Int) -> Void
    let managedCustomAdjustmentDialog: ManagedCustomAdjustmentDialog?
    let onManagedCustomAdjustmentEditTap: (() -> Void)?
    
    @State private var showCustomAdjustmentAlert = false
    @State private var customAdjustmentInput = ""
    @Environment(\.themeColors) private var colors
    
    init(
        selectedAdjustment: AdjustmentAmount,
        customAdjustmentAmount: Int,
        onAdjustmentTapped: @escaping (AdjustmentAmount) -> Void,
        onCustomAdjustmentAmountChanged: @escaping (Int) -> Void,
        managedCustomAdjustmentDialog: ManagedCustomAdjustmentDialog? = nil,
        onManagedCustomAdjustmentEditTap: (() -> Void)? = nil
    ) {
        self.selectedAdjustment = selectedAdjustment
        self.customAdjustmentAmount = customAdjustmentAmount
        self.onAdjustmentTapped = onAdjustmentTapped
        self.onCustomAdjustmentAmountChanged = onCustomAdjustmentAmountChanged
        self.managedCustomAdjustmentDialog = managedCustomAdjustmentDialog
        self.onManagedCustomAdjustmentEditTap = onManagedCustomAdjustmentEditTap
    }
    
    private var resolvedCustomAmount: Int {
        max(customAdjustmentAmount, 1)
    }
    
    private var customAdjustmentAlertPresented: Binding<Bool> {
        Binding(
            get: { managedCustomAdjustmentDialog?.isPresented ?? showCustomAdjustmentAlert },
            set: { isShowing in
                if !isShowing {
                    managedCustomAdjustmentDialog?.onDismiss()
                    showCustomAdjustmentAlert = false
                }
            }
        )
    }
    
    private var customAdjustmentInputBinding: Binding<String> {
        Binding(
            get: { managedCustomAdjustmentDialog?.readInput() ?? customAdjustmentInput },
            set: { newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(4))
                if let managed = managedCustomAdjustmentDialog {
                    managed.onInputChange(filtered)
                } else {
                    customAdjustmentInput = filtered
                }
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AdjustmentAmount.allCases) { amount in
                Group {
                    if amount == .custom {
                        customAdjustmentButton
                    } else {
                        adjustmentButton(for: amount)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .alert(
            String(localized: "customAdjustment.title"),
            isPresented: customAdjustmentAlertPresented
        ) {
            TextField(String(localized: "customAdjustment.placeholder"), text: customAdjustmentInputBinding)
                .keyboardType(.numberPad)
                .accessibilityLabel(String(localized: "customAdjustment.fieldA11y"))
            
            Button(String(localized: "Save")) {
                let raw: String
                if let managed = managedCustomAdjustmentDialog {
                    raw = managed.readInput()
                } else {
                    raw = customAdjustmentInput
                }
                if let parsed = Int(raw), parsed > 0 {
                    onCustomAdjustmentAmountChanged(parsed)
                    managedCustomAdjustmentDialog?.onDismiss()
                    showCustomAdjustmentAlert = false
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "customAdjustment.message"))
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
                .frame(maxWidth: .infinity)
                .background(isSelected ? colors.secondary : colors.tertiary)
                .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
                .cornerRadius(8)
        }
        .accessibilityLabel(amount.displayText(customAmount: resolvedCustomAmount))
    }
    
    private var customAdjustmentButton: some View {
        let isSelected = selectedAdjustment == .custom
        
        return Button {
            if isSelected {
                if let onManagedCustomAdjustmentEditTap {
                    onManagedCustomAdjustmentEditTap()
                } else {
                    customAdjustmentInput = "\(resolvedCustomAmount)"
                    showCustomAdjustmentAlert = true
                }
            } else {
                onAdjustmentTapped(.custom)
            }
        } label: {
            HStack(spacing: 4) {
                Text(AdjustmentAmount.custom.displayText(customAmount: resolvedCustomAmount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "pencil")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 44, minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(isSelected ? colors.secondary : colors.tertiary)
            .foregroundColor(isSelected ? colors.onSecondary : colors.onTertiary)
            .cornerRadius(8)
        }
        .accessibilityLabel(
            String(
                format: String(localized: "customAdjustment.stepButton.a11y"),
                resolvedCustomAmount
            )
        )
        .accessibilityHint(String(localized: "customAdjustment.stepButton.hint"))
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
