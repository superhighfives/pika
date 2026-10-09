import Cocoa
import Defaults
import SwiftUI

// swiftlint:disable identifier_name
// identifier_name is disabled because color component names (r, g, b, a) are standard
// single-letter identifiers used throughout the color APIs.

struct RGBAComponents { let r, g, b, a: CGFloat }

extension CGFloat {
    /// A 0–1 colour value (OpenGL, SwiftUI) to at most 4 decimal places, trailing zeros stripped.
    /// Four places is ±0.00005, well inside one 8-bit step (1/255), so every 8-bit channel still
    /// round-trips. This replaced `%.5g`, whose 5 *significant* digits showed more decimals the
    /// smaller the value (`0.066667`, but `0.53333`) and disagreed with the editor, which caps at
    /// 4 places. Float noise from wide-gamut conversions (e.g. 5.6e-08) rounds to `0`.
    var colorDecimalString: String { strippedDecimalString(maxDecimalPlaces: 4) }
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
            return "Color(red: \(RGB.r.colorDecimalString), green: \(RGB.g.colorDecimalString), "
                + "blue: \(RGB.b.colorDecimalString))"
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
