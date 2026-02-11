import SwiftUI

struct IncreaseDecreaseButtonsView: View {
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let incrementFontSize: CGFloat
    let decrementFontSize: CGFloat
    
    @Environment(\.themeColors) private var colors
    
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
                onDecrement()
            } label: {
                Text("−")
                    .font(.system(size: decrementFontSize, weight: .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colors.tertiary)
                    .foregroundColor(colors.onTertiary)
                    .cornerRadius(16)
            }
            
            Button {
                onIncrement()
            } label: {
                Text("+")
                    .font(.system(size: incrementFontSize, weight: .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colors.primary)
                    .foregroundColor(colors.onPrimary)
                    .cornerRadius(16)
            }
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
