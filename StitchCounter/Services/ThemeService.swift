import SwiftUI
import Combine

@MainActor
final class ThemeService: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeStorageKey)
        }
    }
    
    private let themeStorageKey = "selected_theme"
    
    init() {
        if let storedTheme = UserDefaults.standard.string(forKey: themeStorageKey) {
            self.currentTheme = Self.mapStoredValueToTheme(storedTheme)
        } else {
            self.currentTheme = .seaCottage
        }
    }

    private static func mapStoredValueToTheme(_ storedValue: String) -> AppTheme {
        if let theme = AppTheme(rawValue: storedValue) {
            return theme
        }
        if storedValue == "purple" {
            return .dustyRose
        }
        return .seaCottage
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func colors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeManager.colors(for: currentTheme, isDark: colorScheme == .dark)
    }

    var style: AppThemeStyle {
        AppThemeStyle.style(for: currentTheme)
    }
}
