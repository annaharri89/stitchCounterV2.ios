import SwiftUI

struct IncreaseDecreaseButtonsView: View {
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    @Environment(\.themeColors) private var colors
    
    init(
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) {
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }
    
    var body: some View {
        GeometryReader { container in
            let spacing: CGFloat = 24
            let availableHalfWidth = max(0, (container.size.width - spacing) / 2)
            let rowHeight = min(container.size.height, availableHalfWidth)
            HStack(spacing: spacing) {
                Button {
                    onDecrement()
                } label: {
                    GeometryReader { geometry in
                        let fontSize = Self.scaledSymbolFontSize(for: geometry.size)
                        Text("−")
                            .font(.system(size: fontSize, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(colors.tertiary)
                            .foregroundColor(colors.onTertiary)
                            .cornerRadius(16)
                    }
                }
                .buttonStyle(.plain)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button {
                    onIncrement()
                } label: {
                    GeometryReader { geometry in
                        let fontSize = Self.scaledSymbolFontSize(for: geometry.size)
                        Text("+")
                            .font(.system(size: fontSize, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(colors.primary)
                            .foregroundColor(colors.onPrimary)
                            .cornerRadius(16)
                    }
                }
                .buttonStyle(.plain)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: container.size.width, height: rowHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private static func scaledSymbolFontSize(for size: CGSize) -> CGFloat {
        let side = min(size.width, size.height)
        return min(140, max(44, side * 0.36))
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
