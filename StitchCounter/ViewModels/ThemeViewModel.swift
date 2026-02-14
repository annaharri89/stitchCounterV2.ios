import SwiftUI

@MainActor
final class ThemeViewModel: ObservableObject {
    @Published var selectedTheme: AppTheme

    private let themeService: ThemeService

    init(themeService: ThemeService) {
        self.themeService = themeService
        self.selectedTheme = themeService.currentTheme
    }

    func onThemeSelected(_ theme: AppTheme) {
        selectedTheme = theme
        themeService.setTheme(theme)
    }
}
