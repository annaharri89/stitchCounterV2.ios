import SwiftUI

struct ResetConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    onConfirm()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func resetConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(ResetConfirmationDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            onConfirm: onConfirm
        ))
    }
}
