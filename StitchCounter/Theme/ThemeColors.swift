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
    let onPrimaryContainer: Color
    let onSecondaryContainer: Color
    let onTertiaryContainer: Color
    let error: Color
    let onError: Color
    let surface: Color
    let onSurface: Color
    let background: Color
}

struct ThemeDisplaySwatch: Identifiable {
    let name: String
    let light: Color
    let dark: Color

    var id: String { name }
}

struct ThemeManager {
    static func displaySwatches(for theme: AppTheme) -> [ThemeDisplaySwatch] {
        let lightColors = colors(for: theme, isDark: false)
        let darkColors = colors(for: theme, isDark: true)
        switch theme {
        case .seaCottage:
            return [
                ThemeDisplaySwatch(name: "Mint", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Surf", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Whale Light", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Whale Dark", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        case .goldenHearth:
            return [
                ThemeDisplaySwatch(name: "Terracotta", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Honey", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Sage", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Plum", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        case .forestFiber:
            return [
                ThemeDisplaySwatch(name: "Moss", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Sage", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Wood", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Clay", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        case .cloudSoft:
            return [
                ThemeDisplaySwatch(name: "Misty Blue", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Pale Sky", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Linen", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Mauve", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        case .yarnCandy:
            return [
                ThemeDisplaySwatch(name: "Periwinkle", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Cotton Candy", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Lavender", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Peachy Pink", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        case .dustyRose:
            return [
                ThemeDisplaySwatch(name: "Rose", light: lightColors.primary, dark: darkColors.primary),
                ThemeDisplaySwatch(name: "Blush", light: lightColors.secondary, dark: darkColors.secondary),
                ThemeDisplaySwatch(name: "Sage", light: lightColors.tertiary, dark: darkColors.tertiary),
                ThemeDisplaySwatch(name: "Plum", light: lightColors.quaternary, dark: darkColors.quaternary),
            ]
        }
    }

    static func colors(for theme: AppTheme, isDark: Bool) -> ThemeColors {
        switch theme {
        case .seaCottage:
            return isDark ? seaCottageDarkColors : seaCottageLightColors
        case .dustyRose:
            return isDark ? dustyRoseDarkColors : dustyRoseLightColors
        case .goldenHearth:
            return isDark ? goldenHearthDarkColors : goldenHearthLightColors
        case .forestFiber:
            return isDark ? forestFiberDarkColors : forestFiberLightColors
        case .cloudSoft:
            return isDark ? cloudSoftDarkColors : cloudSoftLightColors
        case .yarnCandy:
            return isDark ? yarnCandyDarkColors : yarnCandyLightColors
        }
    }
    
    // MARK: - Sea Cottage
    
    static let seaCottageLightColors = ThemeColors(
        primary: Color(hex: "1F8A9A"),
        secondary: Color(hex: "3A9B8A"),
        tertiary: Color(hex: "2A5A8A"),
        quaternary: Color(hex: "2A2F7A"),
        primaryContainer: Color(hex: "E8E9FF"),
        secondaryContainer: Color(hex: "E0F5F0"),
        tertiaryContainer: Color(hex: "D6E4FF"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onPrimaryContainer: Color(hex: "002026"),
        onSecondaryContainer: Color(hex: "00201A"),
        onTertiaryContainer: Color(hex: "001C38"),
        error: Color(hex: "B04A4A"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let seaCottageDarkColors = ThemeColors(
        primary: Color(hex: "2FA8B3"),
        secondary: Color(hex: "5FBFA8"),
        tertiary: Color(hex: "3F7FB3"),
        quaternary: Color(hex: "3A2FA3"),
        primaryContainer: Color(hex: "1F3A40"),
        secondaryContainer: Color(hex: "213A35"),
        tertiaryContainer: Color(hex: "1C2B3A"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .white,
        onPrimaryContainer: Color(hex: "AEEAF0"),
        onSecondaryContainer: Color(hex: "A6EDE0"),
        onTertiaryContainer: Color(hex: "C7DCFF"),
        error: Color(hex: "FF8A80"),
        onError: .black,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    // MARK: - Dusty Rose
    
    static let dustyRoseLightColors = ThemeColors(
        primary: Color(hex: "B76E79"),
        secondary: Color(hex: "D8A7B1"),
        tertiary: Color(hex: "7D8F69"),
        quaternary: Color(hex: "6D597A"),
        primaryContainer: Color(hex: "F2DCE0"),
        secondaryContainer: Color(hex: "FFE4EC"),
        tertiaryContainer: Color(hex: "E4EDDA"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onPrimaryContainer: Color(hex: "3A181E"),
        onSecondaryContainer: Color(hex: "3A1420"),
        onTertiaryContainer: Color(hex: "1A2410"),
        error: Color(hex: "B00020"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let dustyRoseDarkColors = ThemeColors(
        primary: Color(hex: "E6A1AA"),
        secondary: Color(hex: "F2C1C6"),
        tertiary: Color(hex: "A3B18A"),
        quaternary: Color(hex: "CDB4DB"),
        primaryContainer: Color(hex: "4A2E33"),
        secondaryContainer: Color(hex: "5A3A40"),
        tertiaryContainer: Color(hex: "2F3A2F"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "F2D0D6"),
        onSecondaryContainer: Color(hex: "FFDAE2"),
        onTertiaryContainer: Color(hex: "D8E8CE"),
        error: Color(hex: "FFB4C0"),
        onError: Color(hex: "5A0F18"),
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    // MARK: - Golden Hearth
    
    static let goldenHearthLightColors = ThemeColors(
        primary: Color(hex: "B85C38"),
        secondary: Color(hex: "D9A441"),
        tertiary: Color(hex: "7A8C66"),
        quaternary: Color(hex: "5E548E"),
        primaryContainer: Color(hex: "F5E0D8"),
        secondaryContainer: Color(hex: "FFEFC8"),
        tertiaryContainer: Color(hex: "E3EAD9"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onPrimaryContainer: Color(hex: "3A1A10"),
        onSecondaryContainer: Color(hex: "2C1E00"),
        onTertiaryContainer: Color(hex: "1A2410"),
        error: Color(hex: "9E2A2B"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let goldenHearthDarkColors = ThemeColors(
        primary: Color(hex: "D9875A"),
        secondary: Color(hex: "E6C065"),
        tertiary: Color(hex: "A3B18A"),
        quaternary: Color(hex: "B8A1E3"),
        primaryContainer: Color(hex: "4A2A22"),
        secondaryContainer: Color(hex: "4A3A1F"),
        tertiaryContainer: Color(hex: "2F3A2F"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "FFDED4"),
        onSecondaryContainer: Color(hex: "FFF0C8"),
        onTertiaryContainer: Color(hex: "D8E8CE"),
        error: Color(hex: "FFB4A9"),
        onError: Color(hex: "5C1D18"),
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    // MARK: - Forest Fiber
    
    static let forestFiberLightColors = ThemeColors(
        primary: Color(hex: "4C6A4D"),
        secondary: Color(hex: "9CAF88"),
        tertiary: Color(hex: "7C5E3C"),
        quaternary: Color(hex: "BC6C25"),
        primaryContainer: Color(hex: "E4F0E6"),
        secondaryContainer: Color(hex: "F1F5E8"),
        tertiaryContainer: Color(hex: "F2E8DC"),
        onPrimary: .white,
        onSecondary: .white,
        onTertiary: .white,
        onPrimaryContainer: Color(hex: "0D2010"),
        onSecondaryContainer: Color(hex: "1A2410"),
        onTertiaryContainer: Color(hex: "2C1A08"),
        error: Color(hex: "8C1D18"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let forestFiberDarkColors = ThemeColors(
        primary: Color(hex: "8FB996"),
        secondary: Color(hex: "CFE1B9"),
        tertiary: Color(hex: "DDB892"),
        quaternary: Color(hex: "FFB870"),
        primaryContainer: Color(hex: "2F3A33"),
        secondaryContainer: Color(hex: "3A443D"),
        tertiaryContainer: Color(hex: "453B2F"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "D4E8D6"),
        onSecondaryContainer: Color(hex: "E0ECD6"),
        onTertiaryContainer: Color(hex: "ECDCC8"),
        error: Color(hex: "FFB4AB"),
        onError: Color(hex: "690005"),
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    // MARK: - Cloud Soft
    
    static let cloudSoftLightColors = ThemeColors(
        primary: Color(hex: "6B8E9F"),
        secondary: Color(hex: "A8C5D1"),
        tertiary: Color(hex: "D9B8A0"),
        quaternary: Color(hex: "9A8C98"),
        primaryContainer: Color(hex: "E3F2F7"),
        secondaryContainer: Color(hex: "F1F7FA"),
        tertiaryContainer: Color(hex: "F5E9E2"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "0A2630"),
        onSecondaryContainer: Color(hex: "142830"),
        onTertiaryContainer: Color(hex: "2E1E12"),
        error: Color(hex: "BA1A1A"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let cloudSoftDarkColors = ThemeColors(
        primary: Color(hex: "9FC5D5"),
        secondary: Color(hex: "CDE7F0"),
        tertiary: Color(hex: "F2D0C2"),
        quaternary: Color(hex: "E0B1CB"),
        primaryContainer: Color(hex: "2A3A40"),
        secondaryContainer: Color(hex: "34474F"),
        tertiaryContainer: Color(hex: "3F332F"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "D0E6F0"),
        onSecondaryContainer: Color(hex: "DAECF2"),
        onTertiaryContainer: Color(hex: "F0DED4"),
        error: Color(hex: "FFB4AB"),
        onError: Color(hex: "690005"),
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    // MARK: - Yarn Candy
    
    static let yarnCandyLightColors = ThemeColors(
        primary: Color(hex: "7B9ACC"),
        secondary: Color(hex: "FFC8DD"),
        tertiary: Color(hex: "CDB4DB"),
        quaternary: Color(hex: "FFAFCC"),
        primaryContainer: Color(hex: "E8ECFF"),
        secondaryContainer: Color(hex: "FFE4F0"),
        tertiaryContainer: Color(hex: "F3E5FF"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "1A1E3A"),
        onSecondaryContainer: Color(hex: "3A0A1E"),
        onTertiaryContainer: Color(hex: "28143A"),
        error: Color(hex: "9C2C54"),
        onError: .white,
        surface: Color(UIColor.systemBackground),
        onSurface: Color(UIColor.label),
        background: Color(UIColor.systemBackground)
    )
    
    static let yarnCandyDarkColors = ThemeColors(
        primary: Color(hex: "B8C0FF"),
        secondary: Color(hex: "FFD6E0"),
        tertiary: Color(hex: "E7C6FF"),
        quaternary: Color(hex: "FFE5EC"),
        primaryContainer: Color(hex: "2E3350"),
        secondaryContainer: Color(hex: "4A2E3A"),
        tertiaryContainer: Color(hex: "3A2E4A"),
        onPrimary: .black,
        onSecondary: .black,
        onTertiary: .black,
        onPrimaryContainer: Color(hex: "DEE0FF"),
        onSecondaryContainer: Color(hex: "FFD8E2"),
        onTertiaryContainer: Color(hex: "EED8FF"),
        error: Color(hex: "FFB1C8"),
        onError: Color(hex: "5A1230"),
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
