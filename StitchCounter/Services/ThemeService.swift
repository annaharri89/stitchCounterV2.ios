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
        if let storedTheme = UserDefaults.standard.string(forKey: themeStorageKey),
           let theme = AppTheme(rawValue: storedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .seaCottage
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func colors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeManager.colors(for: currentTheme, isDark: colorScheme == .dark)
    }
}
