import SwiftUI

enum ThemeButtonStyleType {
    case solidMuted
    case retroShadow
    case gradientGlow
}

enum ThemeHapticStyle {
    case medium
    case rigid
    case soft

    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .medium: return .medium
        case .rigid: return .rigid
        case .soft: return .soft
        }
    }
}

struct AppThemeStyle {
    let counterFontDesign: Font.Design
    let headingFontDesign: Font.Design
    let bodyFontDesign: Font.Design
    let buttonCornerRadius: CGFloat
    let cardCornerRadius: CGFloat
    let incrementSymbol: String
    let decrementSymbol: String
    let buttonStyleType: ThemeButtonStyleType
    let hapticStyle: ThemeHapticStyle

    func performHaptic() {
        let generator = UIImpactFeedbackGenerator(style: hapticStyle.feedbackStyle)
        generator.impactOccurred()
    }
}

extension AppThemeStyle {
    static let cottage = AppThemeStyle(
        counterFontDesign: .rounded,
        headingFontDesign: .rounded,
        bodyFontDesign: .default,
        buttonCornerRadius: 16,
        cardCornerRadius: 16,
        incrementSymbol: "+",
        decrementSymbol: "−",
        buttonStyleType: .solidMuted,
        hapticStyle: .medium
    )

    static let kitschyRetro = AppThemeStyle(
        counterFontDesign: .monospaced,
        headingFontDesign: .monospaced,
        bodyFontDesign: .default,
        buttonCornerRadius: 8,
        cardCornerRadius: 8,
        incrementSymbol: "▲",
        decrementSymbol: "▼",
        buttonStyleType: .retroShadow,
        hapticStyle: .rigid
    )

    static let fairy = AppThemeStyle(
        counterFontDesign: .serif,
        headingFontDesign: .serif,
        bodyFontDesign: .serif,
        buttonCornerRadius: 50,
        cardCornerRadius: 24,
        incrementSymbol: "✦",
        decrementSymbol: "✧",
        buttonStyleType: .gradientGlow,
        hapticStyle: .soft
    )

    static func style(for theme: AppTheme) -> AppThemeStyle {
        switch theme {
        case .seaCottage: return .cottage
        case .retroSummer: return .kitschyRetro
        case .dustyRose: return .fairy
        }
    }
}
