#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets", isDirectory: true)
let iconset = assets.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let preview = assets.appendingPathComponent("DownlinkIcon.png")

try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let data = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "DownlinkIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create PNG data"])
    }

    try data.write(to: url)
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = size * 0.07
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.022)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)

    let outer = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.06, dy: size * 0.06), xRadius: size * 0.20, yRadius: size * 0.20)
    shadow.set()
    NSColor.black.withAlphaComponent(0.26).setFill()
    outer.fill()
    NSShadow().set()

    let base = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.075, dy: size * 0.075), xRadius: size * 0.19, yRadius: size * 0.19)
    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.08, alpha: 1.0),
        NSColor(calibratedWhite: 0.02, alpha: 1.0),
        NSColor(calibratedWhite: 0.13, alpha: 1.0)
    ])!
    gradient.draw(in: base, angle: 42)

    let highlight = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.105, dy: size * 0.105), xRadius: size * 0.16, yRadius: size * 0.16)
    NSColor.white.withAlphaComponent(0.10).setStroke()
    highlight.lineWidth = size * 0.014
    highlight.stroke()

    let whiteGlow = NSShadow()
    whiteGlow.shadowBlurRadius = size * 0.035
    whiteGlow.shadowOffset = .zero
    whiteGlow.shadowColor = NSColor.white.withAlphaComponent(0.28)

    let orbital = NSBezierPath()
    orbital.move(to: NSPoint(x: size * 0.18, y: size * 0.37))
    orbital.curve(to: NSPoint(x: size * 0.86, y: size * 0.69),
                  controlPoint1: NSPoint(x: size * 0.38, y: size * 0.62),
                  controlPoint2: NSPoint(x: size * 0.62, y: size * 0.76))
    orbital.lineCapStyle = .round
    whiteGlow.set()
    NSColor.white.withAlphaComponent(0.88).setStroke()
    orbital.lineWidth = size * 0.026
    orbital.stroke()
    NSShadow().set()

    let silverOrbit = NSBezierPath()
    silverOrbit.move(to: NSPoint(x: size * 0.14, y: size * 0.33))
    silverOrbit.curve(to: NSPoint(x: size * 0.82, y: size * 0.67),
                      controlPoint1: NSPoint(x: size * 0.38, y: size * 0.52),
                      controlPoint2: NSPoint(x: size * 0.58, y: size * 0.71))
    silverOrbit.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.45).setStroke()
    silverOrbit.lineWidth = size * 0.015
    silverOrbit.stroke()

    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: size * 0.37, y: size * 0.72))
    arrow.line(to: NSPoint(x: size * 0.58, y: size * 0.48))
    arrow.move(to: NSPoint(x: size * 0.39, y: size * 0.49))
    arrow.line(to: NSPoint(x: size * 0.58, y: size * 0.48))
    arrow.line(to: NSPoint(x: size * 0.59, y: size * 0.67))
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    NSColor.white.setStroke()
    arrow.lineWidth = size * 0.066
    arrow.stroke()

    let underline = NSBezierPath()
    underline.move(to: NSPoint(x: size * 0.30, y: size * 0.28))
    underline.line(to: NSPoint(x: size * 0.70, y: size * 0.28))
    underline.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.86).setStroke()
    underline.lineWidth = size * 0.038
    underline.stroke()

    let pulse = NSBezierPath()
    pulse.move(to: NSPoint(x: size * 0.63, y: size * 0.74))
    pulse.curve(to: NSPoint(x: size * 0.82, y: size * 0.82),
                controlPoint1: NSPoint(x: size * 0.70, y: size * 0.79),
                controlPoint2: NSPoint(x: size * 0.76, y: size * 0.82))
    pulse.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.26).setStroke()
    pulse.lineWidth = size * 0.018
    pulse.stroke()

    image.unlockFocus()
    return image
}

let icon1024 = drawIcon(size: 1024)
try writePNG(icon1024, to: preview)

let iconNames: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (size, name) in iconNames {
    try writePNG(drawIcon(size: size), to: iconset.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns",
    iconset.path,
    "-o", assets.appendingPathComponent("AppIcon.icns").path
]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    throw NSError(domain: "DownlinkIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

print("Generated \(preview.path)")
print("Generated \(assets.appendingPathComponent("AppIcon.icns").path)")
