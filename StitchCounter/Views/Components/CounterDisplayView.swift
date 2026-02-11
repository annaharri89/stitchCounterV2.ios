import SwiftUI

struct CounterDisplayView: View {
    let count: Int
    let isVertical: Bool
    
    init(count: Int, isVertical: Bool = false) {
        self.count = count
        self.isVertical = isVertical
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let maxFontSize: CGFloat = isVertical ? 200 : 150
            let minFontSize: CGFloat = 48
            
            let digitCount = max(1, String(count).count)
            let widthBasedSize = availableWidth / CGFloat(digitCount) * 1.5
            let heightBasedSize = availableHeight * 0.6
            let calculatedSize = min(widthBasedSize, heightBasedSize)
            let fontSize = min(maxFontSize, max(minFontSize, calculatedSize))
            
            Text("\(count)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    VStack {
        CounterDisplayView(count: 42)
            .frame(height: 100)
        CounterDisplayView(count: 12345, isVertical: true)
            .frame(height: 200)
    }
    .padding()
}
