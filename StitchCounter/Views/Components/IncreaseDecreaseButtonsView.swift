import SwiftUI

struct IncreaseDecreaseButtonsView: View {
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let incrementFontSize: CGFloat
    let decrementFontSize: CGFloat

    @Environment(\.themeColors) private var colors
    @Environment(\.themeStyle) private var style

    init(
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        incrementFontSize: CGFloat = 50,
        decrementFontSize: CGFloat = 60
    ) {
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.incrementFontSize = incrementFontSize
        self.decrementFontSize = decrementFontSize
    }

    var body: some View {
        HStack(spacing: 24) {
            Button {
                style.performHaptic()
                onDecrement()
            } label: {
                Text(style.decrementSymbol)
                    .font(.system(size: decrementFontSize, weight: .medium, design: style.counterFontDesign))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .themedButtonBackground(
                        containerColor: colors.tertiary,
                        contentColor: colors.onTertiary
                    )
            }
            .accessibilityLabel("Decrease count")

            Button {
                style.performHaptic()
                onIncrement()
            } label: {
                Text(style.incrementSymbol)
                    .font(.system(size: incrementFontSize, weight: .medium, design: style.counterFontDesign))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .themedButtonBackground(
                        containerColor: colors.primary,
                        contentColor: colors.onPrimary
                    )
            }
            .accessibilityLabel("Increase count")
        }
    }
}

#Preview {
    IncreaseDecreaseButtonsView(
        onIncrement: {},
        onDecrement: {}
    )
    .frame(height: 100)
    .padding()
}
