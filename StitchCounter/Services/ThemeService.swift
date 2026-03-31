import SwiftUI
import Combine
import UIKit

@MainActor
final class ThemeService: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeStorageKey)
        }
    }

    private let themeStorageKey = "selected_theme"
    private var pendingAlternateIconTheme: AppTheme?
    private var suppressNextAlternateIconApply = false

    private static let logTag = "ThemeService"

    init() {
        if let storedTheme = UserDefaults.standard.string(forKey: themeStorageKey),
           let theme = AppTheme(rawValue: storedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .forestFiber
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applyAlternateIconForTheme(self.currentTheme)
        }
    }

    func colors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeManager.colors(for: currentTheme, isDark: colorScheme == .dark)
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        pendingAlternateIconTheme = theme
    }

    func skipNextPendingAlternateIconApply() {
        suppressNextAlternateIconApply = true
    }

    func applyPendingAlternateIconIfNeeded() {
        if suppressNextAlternateIconApply {
            suppressNextAlternateIconApply = false
            return
        }
        guard let theme = pendingAlternateIconTheme else { return }
        pendingAlternateIconTheme = nil
        applyAlternateIconForTheme(theme)
    }

    private func applyAlternateIconForTheme(_ theme: AppTheme) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("[\(Self.logTag)] event=alternate_icon_skipped reason=unsupported")
            return
        }
        let name = theme.alternateIconAssetName
        if UIApplication.shared.alternateIconName == name {
            return
        }
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error {
                print("[\(Self.logTag)] event=set_alternate_icon_failed name=\(name) error=\(error.localizedDescription)")
            }
        }
    }
}
