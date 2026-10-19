import SwiftUI

// MARK: - Exact Google Antigravity Shape
// Antigravity's signature gravimetric vortex / magnetic field silhouette
public struct AntigravityEmblemShape: Shape {
    public func path(in rect: CGRect) -> Path {
        // Base coordinate space from official SVG: [15, 18] to [95, 96] (width ~80, height ~78)
        let origMinX: CGFloat = 14.0
        let origMinY: CGFloat = 18.4
        let origWidth: CGFloat = 82.0
        let origHeight: CGFloat = 76.0
        
        let scaleX = rect.width / origWidth
        let scaleY = rect.height / origHeight
        
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: rect.minX + (x - origMinX) * scaleX,
                y: rect.minY + (y - origMinY) * scaleY
            )
        }
        
        var path = Path()
        // Official SVG bezier curve definition:
        // M89.6992 93.695
        // C94.3659 97.195 101.366 94.8617 94.9492 88.445
        // C75.6992 69.7783 79.7825 18.445 55.8659 18.445
        // C31.9492 18.445 36.0325 69.7783 16.7825 88.445
        // C9.78251 95.445 17.3658 97.195 22.0325 93.695
        // C40.1159 81.445 38.9492 59.8617 55.8659 59.8617
        // C72.7825 59.8617 71.6159 81.445 89.6992 93.695Z
        path.move(to: pt(89.6992, 93.695))
        path.addCurve(
            to: pt(94.9492, 88.445),
            control1: pt(94.3659, 97.195),
            control2: pt(101.366, 94.8617)
        )
        path.addCurve(
            to: pt(55.8659, 18.445),
            control1: pt(75.6992, 69.7783),
            control2: pt(79.7825, 18.445)
        )
        path.addCurve(
            to: pt(16.7825, 88.445),
            control1: pt(31.9492, 18.445),
            control2: pt(36.0325, 69.7783)
        )
        path.addCurve(
            to: pt(22.0325, 93.695),
            control1: pt(9.78251, 95.445),
            control2: pt(17.3658, 97.195)
        )
        path.addCurve(
            to: pt(55.8659, 59.8617),
            control1: pt(40.1159, 81.445),
            control2: pt(38.9492, 59.8617)
        )
        path.addCurve(
            to: pt(89.6992, 93.695),
            control1: pt(72.7825, 59.8617),
            control2: pt(71.6159, 81.445)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Exact Google Gemini 4-Point Star Sparkle
public struct GeminiSparkleShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        path.move(to: CGPoint(x: midX, y: minY))
        path.addQuadCurve(to: CGPoint(x: maxX, y: midY), control: CGPoint(x: midX, y: midY))
        path.addQuadCurve(to: CGPoint(x: midX, y: maxY), control: CGPoint(x: midX, y: midY))
        path.addQuadCurve(to: CGPoint(x: minX, y: midY), control: CGPoint(x: midX, y: midY))
        path.addQuadCurve(to: CGPoint(x: midX, y: minY), control: CGPoint(x: midX, y: midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Styled Views
public struct AntigravityIconView: View {
    var size: CGFloat = 28
    
    public var body: some View {
        AntigravityEmblemShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.19, green: 0.53, blue: 1.00), // Google Blue (#3186FF)
                        Color(red: 0.65, green: 0.35, blue: 0.95), // DeepMind Violet
                        Color(red: 0.98, green: 0.74, blue: 0.02)  // Antigravity Yellow (#FBBC04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size * 0.95)
            .shadow(color: Color.blue.opacity(0.35), radius: 2)
    }
}

public struct GeminiLogoView: View {
    var size: CGFloat = 28
    
    public var body: some View {
        GeminiSparkleShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.33, green: 0.53, blue: 1.00), // Gemini Blue
                        Color(red: 0.68, green: 0.38, blue: 0.95), // Gemini Violet
                        Color(red: 0.98, green: 0.44, blue: 0.60)  // Gemini Rose
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .shadow(color: Color.blue.opacity(0.35), radius: 2)
    }
}
