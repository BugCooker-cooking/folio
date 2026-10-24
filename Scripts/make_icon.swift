import AppKit
import Foundation

let outputDirectory = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: "Resources/AppIcon.iconset")

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

private func pagePath(rect: NSRect, fold: CGFloat, radius: CGFloat) -> NSBezierPath {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let cut = NSBezierPath()
    cut.move(to: NSPoint(x: rect.maxX - fold, y: rect.maxY))
    cut.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
    cut.line(to: NSPoint(x: rect.maxX, y: rect.maxY - fold))
    cut.close()
    path.append(cut)
    path.windingRule = .evenOdd
    return path
}

private func drawIcon(size: Int) -> NSBitmapImageRep {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: s, height: s).fill()

    let margin = s * 0.085
    let backgroundRect = NSRect(x: margin, y: margin, width: s - margin * 2, height: s - margin * 2)
    let radius = backgroundRect.width * 0.225
    let background = NSBezierPath(roundedRect: backgroundRect, xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    background.addClip()

    let backgroundGradient = NSGradient(colors: [color(0x2B2721), color(0x141311)])!
    backgroundGradient.draw(in: backgroundRect, angle: -68)

    let glowCenter = NSPoint(x: s * 0.34, y: s * 0.72)
    let glow = NSGradient(colors: [
        color(0xB85A36, alpha: 0.21),
        color(0xB85A36, alpha: 0)
    ])!
    glow.draw(
        fromCenter: glowCenter,
        radius: 0,
        toCenter: glowCenter,
        radius: s * 0.62,
        options: []
    )

    let pageWidth = s * 0.39
    let pageHeight = s * 0.47
    let pageRadius = s * 0.046
    let fold = s * 0.086

    // The warm sheet behind the current page.
    let backRect = NSRect(x: s * 0.33, y: s * 0.32, width: pageWidth, height: pageHeight)
    let backPath = NSBezierPath(roundedRect: backRect, xRadius: pageRadius, yRadius: pageRadius)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.42)
    shadow.shadowBlurRadius = s * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    color(0xA84E31).setFill()
    backPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    backPath.addClip()
    let backGradient = NSGradient(colors: [color(0xC26640), color(0x8F3D2B)])!
    backGradient.draw(in: backRect, angle: -62)
    NSGraphicsContext.restoreGraphicsState()

    color(0xD4825B, alpha: 0.55).setStroke()
    backPath.lineWidth = max(1, s * 0.002)
    backPath.stroke()

    // The ivory page with a cut top-right corner.
    let frontRect = NSRect(x: s * 0.30, y: s * 0.29, width: pageWidth, height: pageHeight)
    let frontPath = pagePath(rect: frontRect, fold: fold, radius: pageRadius)

    NSGraphicsContext.saveGraphicsState()
    let frontShadow = NSShadow()
    frontShadow.shadowColor = NSColor.black.withAlphaComponent(0.44)
    frontShadow.shadowBlurRadius = s * 0.032
    frontShadow.shadowOffset = NSSize(width: 0, height: -s * 0.014)
    frontShadow.set()
    color(0xF8F2E6).setFill()
    frontPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Folded-over corner.
    let foldPath = NSBezierPath()
    foldPath.move(to: NSPoint(x: frontRect.maxX - fold, y: frontRect.maxY))
    foldPath.line(to: NSPoint(x: frontRect.maxX, y: frontRect.maxY - fold))
    foldPath.line(to: NSPoint(x: frontRect.maxX - fold, y: frontRect.maxY - fold))
    foldPath.close()
    color(0xE6D9C3).setFill()
    foldPath.fill()

    let crease = NSBezierPath()
    crease.move(to: NSPoint(x: frontRect.maxX - fold, y: frontRect.maxY))
    crease.line(to: NSPoint(x: frontRect.maxX, y: frontRect.maxY - fold))
    color(0xCDBDA4, alpha: 0.8).setStroke()
    crease.lineWidth = max(1, s * 0.0018)
    crease.stroke()

    if size >= 48 {
        // A terracotta margin rule.
        let ruleRect = NSRect(
            x: frontRect.minX + s * 0.045,
            y: frontRect.minY + s * 0.07,
            width: s * 0.009,
            height: frontRect.height - s * 0.14
        )
        color(0xB85A36).setFill()
        NSBezierPath(roundedRect: ruleRect, xRadius: ruleRect.width / 2, yRadius: ruleRect.width / 2).fill()

        // A few quiet text lines.
        let lineWidths: [CGFloat] = [0.21, 0.165, 0.19, 0.125]
        let lineX = frontRect.minX + s * 0.078
        let lineHeight = s * 0.011
        let spacing = s * 0.034
        var top = frontRect.maxY - s * 0.092
        for width in lineWidths {
            let lineRect = NSRect(x: lineX, y: top - lineHeight, width: s * width, height: lineHeight)
            color(0x2A2722, alpha: 0.72).setFill()
            NSBezierPath(roundedRect: lineRect, xRadius: lineHeight / 2, yRadius: lineHeight / 2).fill()
            top -= spacing
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    // A restrained inner rim.
    let rim = NSBezierPath(
        roundedRect: backgroundRect.insetBy(dx: s * 0.0015, dy: s * 0.0015),
        xRadius: radius,
        yRadius: radius
    )
    color(0xFFFFFF, alpha: 0.1).setStroke()
    rim.lineWidth = max(1, s * 0.0018)
    rim.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in variants {
    let rep = drawIcon(size: size)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    try data.write(to: outputDirectory.appendingPathComponent(name))
}

print("Icons written to \(outputDirectory.path)")
