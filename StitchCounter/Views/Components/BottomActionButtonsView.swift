import SwiftUI

struct BottomActionButtonsView: View {
    let onResetAll: () -> Void
    let labelText: String

    @Environment(\.themeColors) private var colors
    @Environment(\.themeStyle) private var style

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
            .font(.system(.headline, design: style.headingFontDesign))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .themedButtonBackground(
                containerColor: colors.quaternary,
                contentColor: .white
            )
        }
        .accessibilityLabel(labelText)
        .accessibilityHint("Resets counters to zero")
    }
}

#Preview {
    VStack {
        BottomActionButtonsView(onResetAll: {}, labelText: "Reset All")
        BottomActionButtonsView(onResetAll: {}, labelText: "Reset")
    }
    .padding()
}
