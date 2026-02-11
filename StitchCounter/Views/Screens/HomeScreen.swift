import SwiftUI

struct HomeScreen: View {
    @Binding var showingSheet: SheetDestination?
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Stitch Counter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button {
                    showingSheet = .newProjectDetail(projectType: .single)
                } label: {
                    HStack {
                        Image(systemName: "number.circle")
                        Text("New Single Tracker")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.primary)
                    .foregroundColor(colors.onPrimary)
                    .cornerRadius(12)
                }
                
                Button {
                    showingSheet = .newProjectDetail(projectType: .double)
                } label: {
                    HStack {
                        Image(systemName: "number.circle.fill")
                        Text("New Double Tracker")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.secondary)
                    .foregroundColor(colors.onSecondary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

#Preview {
    HomeScreen(showingSheet: .constant(nil))
}
