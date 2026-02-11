import SwiftUI

struct BottomActionButtonsView: View {
    let onResetAll: () -> Void
    let labelText: String
    
    @Environment(\.themeColors) private var colors
    
    init(onResetAll: @escaping () -> Void, labelText: String = "Reset") {
        self.onResetAll = onResetAll
        self.labelText = labelText
    }
    
    var body: some View {
        Button {
            onResetAll()
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text(labelText)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(colors.quaternary)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack {
        BottomActionButtonsView(onResetAll: {}, labelText: "Reset All")
        BottomActionButtonsView(onResetAll: {}, labelText: "Reset")
    }
    .padding()
}
