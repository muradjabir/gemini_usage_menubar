import AppKit
import SwiftUI

public final class MenuBarGaugeRenderer {
    public static func renderGaugeIcon(
        agyPercent: Double,
        geminiPercent: Double
    ) -> NSImage {
        let width: CGFloat = 46
        let height: CGFloat = 20
        let image = NSImage(size: NSSize(width: width, height: height))
        
        image.lockFocus()
        
        let gaugeDiameter: CGFloat = 16
        let yOffset: CGFloat = (height - gaugeDiameter) / 2
        let lineWidth: CGFloat = 1.8
        
        // Native template stroke colors
        let baseStrokeColor = NSColor.black
        let trackColor = baseStrokeColor.withAlphaComponent(0.25)
        let progressColor = baseStrokeColor.withAlphaComponent(0.95)
        let logoColor = baseStrokeColor.withAlphaComponent(0.95)
        
        // 1. Antigravity Gauge (Left)
        let agyRect = NSRect(x: 2, y: yOffset, width: gaugeDiameter, height: gaugeDiameter)
        drawCircularGauge(
            in: agyRect,
            percent: agyPercent,
            lineWidth: lineWidth,
            trackColor: trackColor,
            progressColor: progressColor
        )
        // Center Antigravity vector emblem (approx 10x10)
        let agyLogoRect = NSRect(x: 5.2, y: yOffset + 3.0, width: 9.6, height: 10.0)
        drawAntigravityEmblem(in: agyLogoRect, color: logoColor)
        
        // 2. Gemini Gauge (Right)
        let gemRect = NSRect(x: 24, y: yOffset, width: gaugeDiameter, height: gaugeDiameter)
        drawCircularGauge(
            in: gemRect,
            percent: geminiPercent,
            lineWidth: lineWidth,
            trackColor: trackColor,
            progressColor: progressColor
        )
        // Center Gemini sparkle vector logo
        // Increased from 9x9 to 11.5x11.5 with full-bleed tip curves for prominent visibility
        let gemLogoRect = NSRect(x: 26.25, y: yOffset + 2.25, width: 11.5, height: 11.5)
        drawGeminiSparkle(in: gemLogoRect, color: logoColor)
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private static func drawCircularGauge(
        in rect: NSRect,
        percent: Double,
        lineWidth: CGFloat,
        trackColor: NSColor,
        progressColor: NSColor
    ) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = (rect.width - lineWidth) / 2
        
        // Track Path
        let trackPath = NSBezierPath()
        trackPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        trackPath.lineWidth = lineWidth
        trackColor.setStroke()
        trackPath.stroke()
        
        // Progress Arc (Starting from 90° top, going clockwise)
        let fraction = min(max(percent / 100.0, 0.0), 1.0)
        if fraction > 0.01 {
            let progressPath = NSBezierPath()
            let startAngle: CGFloat = 90
            let endAngle: CGFloat = 90 - (fraction * 360)
            progressPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            progressPath.lineWidth = lineWidth
            progressPath.lineCapStyle = .round
            
            progressColor.setStroke()
            progressPath.stroke()
        }
    }
    
    private static func drawAntigravityEmblem(in rect: NSRect, color: NSColor) {
        let origMinX: CGFloat = 14.0
        let origMinY: CGFloat = 18.4
        let origWidth: CGFloat = 82.0
        let origHeight: CGFloat = 76.0
        
        let scaleX = rect.width / origWidth
        let scaleY = rect.height / origHeight
        
        func pt(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(
                x: rect.minX + (x - origMinX) * scaleX,
                y: rect.minY + (origHeight - (y - origMinY)) * scaleY
            )
        }
        
        let path = NSBezierPath()
        path.move(to: pt(89.6992, 93.695))
        path.curve(to: pt(94.9492, 88.445), controlPoint1: pt(94.3659, 97.195), controlPoint2: pt(101.366, 94.8617))
        path.curve(to: pt(55.8659, 18.445), controlPoint1: pt(75.6992, 69.7783), controlPoint2: pt(79.7825, 18.445))
        path.curve(to: pt(16.7825, 88.445), controlPoint1: pt(31.9492, 18.445), controlPoint2: pt(36.0325, 69.7783))
        path.curve(to: pt(22.0325, 93.695), controlPoint1: pt(9.78251, 95.445), controlPoint2: pt(17.3658, 97.195))
        path.curve(to: pt(55.8659, 59.8617), controlPoint1: pt(40.1159, 81.445), controlPoint2: pt(38.9492, 59.8617))
        path.curve(to: pt(89.6992, 93.695), controlPoint1: pt(72.7825, 59.8617), controlPoint2: pt(71.6159, 81.445))
        path.close()
        
        color.setFill()
        path.fill()
    }
    
    private static func drawGeminiSparkle(in rect: NSRect, color: NSColor) {
        let midX = rect.midX
        let midY = rect.midY
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        // Control point inset factor: 0.15 gives fuller, clearly visible diamond star body
        let insetX = (maxX - minX) * 0.18
        let insetY = (maxY - minY) * 0.18
        
        let path = NSBezierPath()
        path.move(to: NSPoint(x: midX, y: maxY))
        path.curve(to: NSPoint(x: maxX, y: midY), controlPoint1: NSPoint(x: midX + insetX, y: midY + insetY), controlPoint2: NSPoint(x: midX + insetX, y: midY + insetY))
        path.curve(to: NSPoint(x: midX, y: minY), controlPoint1: NSPoint(x: midX + insetX, y: midY - insetY), controlPoint2: NSPoint(x: midX + insetX, y: midY - insetY))
        path.curve(to: NSPoint(x: minX, y: midY), controlPoint1: NSPoint(x: midX - insetX, y: midY - insetY), controlPoint2: NSPoint(x: midX - insetX, y: midY - insetY))
        path.curve(to: NSPoint(x: midX, y: maxY), controlPoint1: NSPoint(x: midX - insetX, y: midY + insetY), controlPoint2: NSPoint(x: midX - insetX, y: midY + insetY))
        path.close()
        
        color.setFill()
        path.fill()
    }
}
