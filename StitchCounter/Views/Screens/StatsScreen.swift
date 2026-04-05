import SwiftUI

struct StatsScreen: View {
    @Environment(\.themeColors) private var colors

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: 0)
                        comingSoonContent
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .padding(32)
                }
            }
            .navigationTitle(String(localized: "nav.stats"))
        }
    }

    private var comingSoonContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundStyle(colors.onSurface.opacity(0.4))
                .accessibilityLabel(String(localized: "stats.comingSoon.icon.accessibility"))

            Text("stats.comingSoon.title")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(colors.onSurface)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("stats.comingSoon.message")
                .font(.body)
                .foregroundStyle(colors.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsScreen()
        .themeColors(ThemeManager.seaCottageLightColors)
}
