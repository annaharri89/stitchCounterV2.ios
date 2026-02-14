import SwiftUI

struct HomeScreen: View {
    @Binding var showingSheet: SheetDestination?

    @Environment(\.themeColors) private var colors
    @Environment(\.themeStyle) private var style

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Stitch Counter")
                .font(.system(.largeTitle, design: style.headingFontDesign))
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Button {
                    showingSheet = .newProjectDetail(projectType: .single)
                } label: {
                    HStack {
                        Image(systemName: "number.circle")
                        Text("New Single Tracker")
                    }
                    .font(.system(.headline, design: style.headingFontDesign))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .themedButtonBackground(
                        containerColor: colors.primary,
                        contentColor: colors.onPrimary
                    )
                }
                .accessibilityLabel("New Single Tracker")
                .accessibilityHint("Creates a new single stitch counter")

                Button {
                    showingSheet = .newProjectDetail(projectType: .double)
                } label: {
                    HStack {
                        Image(systemName: "number.circle.fill")
                        Text("New Double Tracker")
                    }
                    .font(.system(.headline, design: style.headingFontDesign))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .themedButtonBackground(
                        containerColor: colors.secondary,
                        contentColor: colors.onSecondary
                    )
                }
                .accessibilityLabel("New Double Tracker")
                .accessibilityHint("Creates a new double stitch and row counter")
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

#Preview {
    HomeScreen(showingSheet: .constant(nil))
}
