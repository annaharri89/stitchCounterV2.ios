import SwiftUI

struct ThemeScreen: View {
    @ObservedObject var viewModel: ThemeViewModel

    @Environment(\.themeColors) private var colors

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: viewModel.selectedTheme == theme,
                            onSelect: { viewModel.onThemeSelected(theme) }
                        )
                    }
                } header: {
                    Text("Choose a Color Scheme")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Theme")
        }
    }
}

// MARK: - Theme Option Row

private struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.themeColors) private var colors

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundColor(colors.onSurface)

                    if isSelected {
                        themeColorPreviews
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface.opacity(0.4))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(theme.displayName)
        .accessibilityHint(isSelected ? "Currently selected theme" : "Double tap to select this theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var themeColorPreviews: some View {
        let previewColors = ThemeManager.colors(for: theme, isDark: false)
        return HStack(spacing: 8) {
            Circle().fill(previewColors.primary).frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Circle().fill(previewColors.secondary).frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Circle().fill(previewColors.tertiary).frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Circle().fill(previewColors.quaternary).frame(width: 20, height: 20)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    ThemeScreen(
        viewModel: ThemeViewModel(themeService: ThemeService())
    )
}
