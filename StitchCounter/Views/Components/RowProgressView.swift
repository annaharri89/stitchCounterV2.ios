import SwiftUI

struct RowProgressView: View {
    let currentRowCount: Int
    let totalRows: Int
    
    @Environment(\.themeColors) private var colors
    
    private var progress: Float? {
        guard totalRows > 0 else { return nil }
        return min(1.0, Float(currentRowCount) / Float(totalRows))
    }
    
    var body: some View {
        if let progress = progress {
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                
                Text("\(currentRowCount)/\(totalRows)")
                    .font(.caption)
                    .foregroundColor(colors.onSurface.opacity(0.6))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RowProgressView(currentRowCount: 10, totalRows: 20)
        RowProgressView(currentRowCount: 15, totalRows: 20)
        RowProgressView(currentRowCount: 20, totalRows: 20)
        RowProgressView(currentRowCount: 0, totalRows: 0)
    }
    .padding()
}
