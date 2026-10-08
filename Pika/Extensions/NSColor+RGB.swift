import Cocoa
import Defaults
import SwiftUI

// swiftlint:disable identifier_name
// identifier_name is disabled because color component names (r, g, b, a) are standard
// single-letter identifiers used throughout the color APIs.

struct RGBAComponents { let r, g, b, a: CGFloat }

extension CGFloat {
    /// `%.5g`, reading float noise below 1e-6 as 0. Converting a wide-gamut colour between spaces
    /// can leave e.g. 5.6e-08 where a channel should be 0, which `%.5g` prints in scientific
    /// notation. Applied only when formatting: rounding the components themselves would leak
    /// into the Lab/OKLCH maths and shift values sitting on a rounding boundary.
    var fiveSignificantDigits: String { String(format: "%.5g", abs(self) < 1e-6 ? 0 : self) }
}

extension NSColor {
    final func toRGBAComponents(in colorSpace: NSColorSpace = Defaults[.colorSpace]) -> RGBAComponents {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        guard let rgbaColor = usingColorSpace(colorSpace) else {
            fatalError("Could not convert color to RGBA")
        }

        rgbaColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return RGBAComponents(r: r, g: g, b: b, a: a)
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
            return "Color(red: \(RGB.r.fiveSignificantDigits), green: \(RGB.g.fiveSignificantDigits), "
                + "blue: \(RGB.b.fiveSignificantDigits))"
        case .unformatted:
            return String(format: "%d, %d, %d", red, green, blue)
        }
    }

    func toRGB8BitArray(in colorSpace: NSColorSpace = .sRGB) -> [Int] {
        let RGB = toRGBAComponents(in: colorSpace)
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

    // Black or white — whichever has the higher WCAG contrast against this colour — for legible
    // text/UI drawn on top of it. The crossover (equal contrast to black and white) is at a
    // relative luminance of ~0.179, not 0.5: black wins for everything brighter than that.
    private static let uiColorCrossover: CGFloat = 0.179

    func getUIColor() -> Color {
        luminance < Self.uiColorCrossover ? Color.white : Color.black
    }

    func getUIColor() -> NSColor {
        luminance < Self.uiColorCrossover ? NSColor.white : NSColor.black
    }
}

// swiftlint:enable identifier_name
