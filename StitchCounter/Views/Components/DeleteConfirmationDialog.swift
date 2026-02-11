import SwiftUI

struct DeleteConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let projectCount: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    private var title: String {
        projectCount == 1 ? "Delete Project?" : "Delete Projects?"
    }
    
    private var message: String {
        projectCount == 1
            ? "Are you sure you want to delete this project? This action cannot be undone."
            : "Are you sure you want to delete \(projectCount) projects? This action cannot be undone."
    }
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                Button("Delete", role: .destructive) {
                    onConfirm()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func deleteConfirmationDialog(
        isPresented: Binding<Bool>,
        projectCount: Int,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationDialog(
            isPresented: isPresented,
            projectCount: projectCount,
            onConfirm: onConfirm,
            onCancel: onCancel
        ))
    }
}
