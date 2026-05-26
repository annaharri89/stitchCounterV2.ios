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
    private let logger: FileLogging

    private static let logTag = "ThemeService"

    init(logger: FileLogging = FileLogger.shared) {
        self.logger = logger
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
        logger.info(
            tag: Self.logTag,
            message: "Theme selected",
            metadata: ["theme": theme.rawValue]
        )
    }

    func skipNextPendingAlternateIconApply() {
        suppressNextAlternateIconApply = true
        logger.debug(tag: Self.logTag, message: "Skipping pending alternate icon apply", metadata: nil)
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
        logger.debug(
            tag: Self.logTag,
            message: "Applying alternate icon for theme",
            metadata: ["theme": theme.rawValue]
        )
        guard UIApplication.shared.supportsAlternateIcons else {
            logger.warning(
                tag: Self.logTag,
                message: "Alternate icons unsupported",
                metadata: ["theme": theme.rawValue]
            )
            return
        }
        let name = theme.alternateIconAssetName
        if UIApplication.shared.alternateIconName == name {
            logger.debug(
                tag: Self.logTag,
                message: "Alternate icon already active",
                metadata: ["iconName": name ?? "primary"]
            )
            return
        }
        logger.info(
            tag: Self.logTag,
            message: "Setting alternate icon",
            metadata: ["iconName": name ?? "primary"]
        )
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error {
                self.logger.error(
                    tag: Self.logTag,
                    message: "Failed to set alternate icon",
                    metadata: [
                        "iconName": name ?? "primary",
                        "error": error.localizedDescription
                    ]
                )
            }
        }
    }
}
