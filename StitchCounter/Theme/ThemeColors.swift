import SwiftUI

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let quaternary: Color
    let primaryContainer: Color
    let secondaryContainer: Color
    let tertiaryContainer: Color
    let onPrimary: Color
    let onSecondary: Color
    let onTertiary: Color
    let onTertiaryContainer: Color
    let error: Color
    let onError: Color
    let surface: Color
    let onSurface: Color
    let background: Color
}

struct ThemeManager {
    static func colors(for theme: AppTheme, isDark: Bool) -> ThemeColors {
        switch theme {
        case .seaCottage:
            return isDark ? seaCottageDarkColors : seaCottageLightColors
        case .retroSummer:
            return isDark ? retroSummerDarkColors : retroSummerLightColors
        case .purple:
            return isDark ? purpleDarkColors : purpleLightColors
        }
    }
    
    static let seaCottageLightColors = ThemeColors(
        primary: Color(hex: "1F8A9A"),
        secondary: Color(hex: "3A9B8A"),
        tertiary: Color(hex: "2A5A8A"),
        quaternary: Color(hex: "2A2F7A"),
        primaryContainer: Color(hex: "E8E9FF"),
        secondaryContainer: Color(hex: "E0F5F0"),
        tertiaryContainer: Color(hex: "D0C0E8"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onTertiaryContainer: Color(hex: "2A1F4A"),
        error: Color(hex: "D32F2F"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let seaCottageDarkColors = ThemeColors(
        primary: Color(hex: "36C2CE"),
        secondary: Color(hex: "77E4C8"),
        tertiary: Color(hex: "478CCF"),
        quaternary: Color(hex: "4535C1"),
        primaryContainer: Color(hex: "6B7BC7"),
        secondaryContainer: Color(hex: "4A7B6B"),
        tertiaryContainer: Color(hex: "3A2A6B"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .white,
        onTertiaryContainer: Color(hex: "E8D6FF"),
        error: Color(hex: "FF6B6B"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let retroSummerLightColors = ThemeColors(
        primary: Color(hex: "2A7B5A"),
        secondary: Color(hex: "9B7A2A"),
        tertiary: Color(hex: "C86A2A"),
        quaternary: Color(hex: "9B4A2A"),
        primaryContainer: Color(hex: "FFF4F0"),
        secondaryContainer: Color(hex: "FFF8E0"),
        tertiaryContainer: Color(hex: "FFE8D0"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onTertiaryContainer: Color(hex: "4A2A1F"),
        error: Color(hex: "C62828"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let retroSummerDarkColors = ThemeColors(
        primary: Color(hex: "36BA98"),
        secondary: Color(hex: "E9C46A"),
        tertiary: Color(hex: "F4A261"),
        quaternary: Color(hex: "E76F51"),
        primaryContainer: Color(hex: "C47A5A"),
        secondaryContainer: Color(hex: "9B7A4A"),
        tertiaryContainer: Color(hex: "9B5A2A"),
        onPrimary: .white,
        onSecondary: .black,
        onTertiary: .white,
        onTertiaryContainer: Color(hex: "FFD6B0"),
        error: Color(hex: "FF5252"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let purpleLightColors = ThemeColors(
        primary: Color(hex: "6650A4"),
        secondary: Color(hex: "625B71"),
        tertiary: Color(hex: "7D5260"),
        quaternary: Color(hex: "4A2C3A"),
        primaryContainer: Color(hex: "E8DEF8"),
        secondaryContainer: Color(hex: "E8E0F0"),
        tertiaryContainer: Color(hex: "FFE0E8"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onTertiaryContainer: Color(hex: "4A1F2A"),
        error: Color(hex: "C2185B"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let purpleDarkColors = ThemeColors(
        primary: Color(hex: "D0BCFF"),
        secondary: Color(hex: "CCC2DC"),
        tertiary: Color(hex: "EFB8C8"),
        quaternary: Color(hex: "B88FA3"),
        primaryContainer: Color(hex: "4F378B"),
        secondaryContainer: Color(hex: "4A3A5A"),
        tertiaryContainer: Color(hex: "5A2A3A"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onTertiaryContainer: Color(hex: "FFD6E0"),
        error: Color(hex: "FF6B9D"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
