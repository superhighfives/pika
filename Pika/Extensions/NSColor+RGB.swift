import Cocoa
import Defaults
import SwiftUI

// swiftlint:disable identifier_name

extension NSColor {
    final func toRGBAComponents(in colorSpace: NSColorSpace = Defaults[.colorSpace])
        -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
    {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        guard let rgbaColor = usingColorSpace(colorSpace) else {
            fatalError("Could not convert color to RGBA")
        }

        rgbaColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return (r, g, b, a)
    }

    func toRGBString(style: CopyFormat = .css) -> String {
        let RGB = toRGBAComponents()
        let red = Int(round(RGB.r * 255))
        let green = Int(round(RGB.g * 255))
        let blue = Int(round(RGB.b * 255))

        switch style {
        case .css, .design:
            return String(format: "rgb(%d, %d, %d)", red, green, blue)
        case .swiftUI:
            return String(format: "Color(red: %.5g, green: %.5g, blue: %.5g)", RGB.r, RGB.g, RGB.b)
        case .unformatted:
            return String(format: "%d, %d, %d", red, green, blue)
        }
    }

    func toRGB8BitArray() -> [Int] {
        let RGB = toRGBAComponents()
        let red = Int(round(RGB.r * 255))
        let green = Int(round(RGB.g * 255))
        let blue = Int(round(RGB.b * 255))
        return [red, green, blue]
    }

    func toFormat(format: ColorFormat, style: CopyFormat = .css) -> String {
        switch format {
        case .hex:
            return toHexString(style: style)
        case .rgb:
            return toRGBString(style: style)
        case .hsb:
            return toHSBString(style: style)
        case .hsl:
            return toHSLString(style: style)
        case .opengl:
            return toOpenGLString(style: style)
        case .lab:
            return toLabString(style: style)
        case .oklch:
            return toOklchString(style: style)
        }
    }

    func getUIColor() -> Color {
        luminance < 0.5 ? Color.white : Color.black
    }

    func getUIColor() -> NSColor {
        luminance < 0.5 ? NSColor.white : NSColor.black
    }
}

// swiftlint:enable identifier_name
