import Cocoa
import Defaults
import SwiftUI

// swiftlint:disable identifier_name

extension NSColor {
    /*
     * Initialisers
     */

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (r > 1) || (g > 1) || (b > 1) {
            self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
        } else {
            self.init(red: r, green: g, blue: b, alpha: a)
        }
    }

    /**
     Create a UIColor with a string hex value.

     - parameter hex:     The hex color, i.e. "FF0072" or "#FF0072".
     - parameter alpha:   The opacity of the color, value between [0,1]. Optional. Default: 1
     */
    convenience init(hex: String, alpha: CGFloat = 1) {
        var hex = hex.replacingOccurrences(of: "#", with: "")

        guard hex.count == 3 || hex.count == 6 else {
            fatalError("Hex characters must be either 3 or 6 characters.")
        }

        if hex.count == 3 {
            let tmp = hex
            hex = ""
            for c in tmp {
                hex += String([c, c])
            }
        }

        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let R = CGFloat((rgb >> 16) & 0xFF) / 255
        let G = CGFloat((rgb >> 8) & 0xFF) / 255
        let B = CGFloat(rgb & 0xFF) / 255
        self.init(red: R, green: G, blue: B, alpha: alpha)
    }

    /*
     * Utilities
     */

    func clip<T: Comparable>(_ v: T, _ minimum: T, _ maximum: T) -> T {
        max(min(v, maximum), minimum)
    }

    func contrastRatio(with color: NSColor) -> CGFloat {
        let L1 = luminance
        let L2 = color.luminance

        if L1 < L2 {
            return (L2 + 0.05) / (L1 + 0.05)
        } else {
            return (L1 + 0.05) / (L2 + 0.05)
        }
    }

    func toContrastRatioString(with color: NSColor) -> String {
        Double(round(100 * contrastRatio(with: color)) / 100).description as String
    }

    var luminance: CGFloat {
        let rgba = toRGBAComponents(in: .extendedSRGB)

        func lumHelper(c: CGFloat) -> CGFloat {
            (c < 0.03928) ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }

        let result = 0.2126 * lumHelper(c: rgba.r) + 0.7152 * lumHelper(c: rgba.g) + 0.0722 * lumHelper(c: rgba.b)
        return max(.zero, result)
    }

    /*
     * Hex
     */

    func roundToHex(_ x: CGFloat) -> UInt32 {
        guard x > 0 else { return 0 }
        let rounded: CGFloat = round(x * 255.0)
        return UInt32(rounded)
    }

    func toHex() -> UInt32 {
        let rgba = toRGBAComponents()
        return roundToHex(rgba.r) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.b)
    }

    func toHexString(style: CopyFormat = .css) -> String {
        String(format: style == .css ? "#%06x" : "%06x", toHex())
    }

    /*
     * RGBA
     */

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

    /**
     Get the rgb values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit rgb string.
     */
    func toRGBString(style: CopyFormat = .css) -> String {
        let RGB = toRGBAComponents()
        let red = Int(round(RGB.r * 255))
        let green = Int(round(RGB.g * 255))
        let blue = Int(round(RGB.b * 255))

        let rgbString: String
        switch style {
        case .css, .design:
            rgbString = String(format: "rgb(%d, %d, %d)", red, green, blue)
        case .swiftUI:
            rgbString = String(format: "Color(red: %.5g, green: %.5g, blue: %.5g)", RGB.r, RGB.g, RGB.b)
        case .unformatted:
            rgbString = String(format: "%d, %d, %d", red, green, blue)
        }

        return rgbString
    }

    /**
     Get the rgb values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit rgb array.
     */
    func toRGB8BitArray() -> [Int] {
        let RGB = toRGBAComponents()
        let red = Int(round(RGB.r * 255))
        let green = Int(round(RGB.g * 255))
        let blue = Int(round(RGB.b * 255))
        return [red, green, blue]
    }

    /*
     * Helpers
     */

    /**
     Returns hex and string formats of each color

     - returns: A string of the color depending on the provided format.
     */
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

    func getUIColor() -> (Color) {
        luminance < 0.5 ? Color.white : Color.black
    }

    func getUIColor() -> (NSColor) {
        luminance < 0.5 ? NSColor.white : NSColor.black
    }
}

// swiftlint:enable identifier_name
