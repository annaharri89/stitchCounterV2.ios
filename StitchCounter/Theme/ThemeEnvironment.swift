import SwiftUI

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = ThemeManager.seaCottageLightColors
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

extension View {
    func themeColors(_ colors: ThemeColors) -> some View {
        environment(\.themeColors, colors)
    }
}
