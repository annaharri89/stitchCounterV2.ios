import SwiftUI

struct ThemedButtonBackground: ViewModifier {
    let containerColor: Color
    let contentColor: Color

    @Environment(\.themeStyle) private var style

    func body(content: Content) -> some View {
        switch style.buttonStyleType {
        case .solidMuted:
            content
                .foregroundColor(contentColor)
                .background(containerColor)
                .clipShape(RoundedRectangle(cornerRadius: style.buttonCornerRadius))

        case .retroShadow:
            content
                .foregroundColor(contentColor)
                .background(containerColor)
                .clipShape(ScallopedShape())
                .overlay(
                    ScallopedShape()
                        .stroke(contentColor.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 0, x: 4, y: 4)

        case .gradientGlow:
            let gradientEndColor = blendedWithWhite(containerColor, ratio: 0.35)
            content
                .foregroundColor(contentColor)
                .background(
                    LinearGradient(
                        colors: [containerColor, gradientEndColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: style.buttonCornerRadius))
                .shadow(color: containerColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }

    private func blendedWithWhite(_ color: Color, ratio: Double) -> Color {
        let resolved = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Color(
            red: red + (1.0 - red) * ratio,
            green: green + (1.0 - green) * ratio,
            blue: blue + (1.0 - blue) * ratio
        )
    }
}

extension View {
    func themedButtonBackground(
        containerColor: Color,
        contentColor: Color
    ) -> some View {
        modifier(ThemedButtonBackground(
            containerColor: containerColor,
            contentColor: contentColor
        ))
    }
}
