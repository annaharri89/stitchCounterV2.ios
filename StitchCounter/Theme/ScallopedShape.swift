import SwiftUI

struct ScallopedShape: Shape {
    let scallopDepth: CGFloat

    init(scallopDepth: CGFloat = 3) {
        self.scallopDepth = scallopDepth
    }

    func path(in rect: CGRect) -> Path {
        let scallopWidth = scallopDepth * 5
        let horizontalCount = max(3, Int(rect.width / scallopWidth))
        let actualScallopWidth = rect.width / CGFloat(horizontalCount)

        var path = Path()

        path.move(to: CGPoint(x: 0, y: scallopDepth))

        for scallop in 0..<horizontalCount {
            let controlX = CGFloat(scallop) * actualScallopWidth + actualScallopWidth / 2
            let endX = CGFloat(scallop + 1) * actualScallopWidth
            path.addQuadCurve(
                to: CGPoint(x: endX, y: scallopDepth),
                control: CGPoint(x: controlX, y: -scallopDepth * 0.4)
            )
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height - scallopDepth))

        for scallop in stride(from: horizontalCount - 1, through: 0, by: -1) {
            let controlX = CGFloat(scallop) * actualScallopWidth + actualScallopWidth / 2
            let endX = CGFloat(scallop) * actualScallopWidth
            path.addQuadCurve(
                to: CGPoint(x: endX, y: rect.height - scallopDepth),
                control: CGPoint(x: controlX, y: rect.height + scallopDepth * 0.4)
            )
        }

        path.closeSubpath()
        return path
    }
}
