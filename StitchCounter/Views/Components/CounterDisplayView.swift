import SwiftUI

struct CounterDisplayView: View {
    let count: Int
    let isVertical: Bool
    var verticalContentAlignment: Alignment
    
    init(
        count: Int,
        isVertical: Bool = false,
        verticalContentAlignment: Alignment = .center
    ) {
        self.count = count
        self.isVertical = isVertical
        self.verticalContentAlignment = verticalContentAlignment
    }
    
    var body: some View {
        GeometryReader { geometry in
            let layoutSlots = Self.formattedLayoutSlotCount(for: count)
            let fontSize = Self.fontSize(
                isVertical: isVertical,
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height,
                layoutSlots: layoutSlots
            )
            
            Text("\(count)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(isVertical ? 1 : 0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: verticalContentAlignment)
        }
    }
    
    /// Width budget for sizing matches grouped decimal strings (e.g. `8,900`), so font size stays
    /// constant while the digit count and grouping separators are unchanged.
    private static func formattedLayoutSlotCount(for count: Int) -> Int {
        let digitCount = max(1, String(abs(count)).count)
        let groupSeparators = digitCount > 3 ? (digitCount - 1) / 3 : 0
        return digitCount + groupSeparators
    }
    
    private static func fontSize(
        isVertical: Bool,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        layoutSlots: Int
    ) -> CGFloat {
        let minFontSize: CGFloat = 48
        let slotWidthDivisor: CGFloat = isVertical ? 0.74 : 0.58
        let calculatedSize: CGFloat
        let maxFontSize: CGFloat
        if isVertical {
            let fromHeight = availableHeight * 0.78
            let widthLimitedSize = availableWidth / CGFloat(layoutSlots) / slotWidthDivisor
            calculatedSize = min(fromHeight, widthLimitedSize)
            maxFontSize = min(560, availableHeight * 0.92)
        } else {
            let fromHeight = availableHeight * 0.6
            let fromWidth = availableWidth * 0.3
            let perSlotWidthCap = availableWidth / CGFloat(layoutSlots) / slotWidthDivisor
            calculatedSize = min(fromHeight, min(fromWidth, perSlotWidthCap))
            maxFontSize = 96
        }
        return min(maxFontSize, max(minFontSize, calculatedSize))
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
