import SwiftUI

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = ThemeManager.seaCottageLightColors
}

private struct ThemeStyleKey: EnvironmentKey {
    static let defaultValue: AppThemeStyle = .cottage
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }

    var themeStyle: AppThemeStyle {
        get { self[ThemeStyleKey.self] }
        set { self[ThemeStyleKey.self] = newValue }
    }
}

extension View {
    func themeColors(_ colors: ThemeColors) -> some View {
        environment(\.themeColors, colors)
    }

    func themeStyle(_ style: AppThemeStyle) -> some View {
        environment(\.themeStyle, style)
    }
}
