import Cocoa
import Defaults
import SwiftUI

// swiftlint:disable identifier_name

extension NSColor {
    // Initialiser

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (r > 1) || (g > 1) || (b > 1) {
            self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
        } else {
            self.init(red: r, green: g, blue: b, alpha: a)
        }
    }

    // Utils
    internal func clip<T: Comparable>(_ v: T, _ minimum: T, _ maximum: T) -> T {
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
        let rgba = toRGBAComponents()

        func lumHelper(c: CGFloat) -> CGFloat {
            (c < 0.03928) ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * lumHelper(c: rgba.r) + 0.7152 * lumHelper(c: rgba.g) + 0.0722 * lumHelper(c: rgba.b)
    }

    // Color modification

    func overlay(with color: NSColor) -> NSColor {
        let mainRGBA = toRGBAComponents()
        let maskRGBA = color.toRGBAComponents()

        func masker(a: CGFloat, b: CGFloat) -> CGFloat {
            if a < 0.5 {
                return 2 * a * b
            } else {
                return 1 - (2 * (1 - a) * (1 - b))
            }
        }

        return NSColor(
            r: masker(a: mainRGBA.r, b: maskRGBA.r),
            g: masker(a: mainRGBA.g, b: maskRGBA.g),
            b: masker(a: mainRGBA.b, b: maskRGBA.b),
            a: masker(a: mainRGBA.a, b: maskRGBA.a)
        )
    }

    //  Hex

    internal func roundToHex(_ x: CGFloat) -> UInt32 {
        guard x > 0 else { return 0 }
        let rounded: CGFloat = round(x * 255.0)

        return UInt32(rounded)
    }

    func toHexString() -> String {
        String(format: "#%06x", toHex())
    }

    func toHex() -> UInt32 {
        let rgba = toRGBAComponents()

        return roundToHex(rgba.r) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.b)
    }

    // RGBA
    // swiftlint:disable large_tuple
    final func toRGBAComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        guard let rgbaColor = usingColorSpace(Defaults[.colorSpace]) else {
            fatalError("Could not convert color to RGBA.")
        }

        rgbaColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return (r, g, b, a)
    }

    // swiftlint:enable large_tuple

    /**
     Get the rgb values of this color.

     - returns: An NSColor as an rgb string.
     */
    func toRGBString() -> String {
        let RGB = toRGBAComponents()
        let red = RGB.r
        let green = RGB.g
        let blue = RGB.b
        let rgbString = NSString(format: "rgb(%f, %f, %f)", red, green, blue)
        return rgbString as String
    }

    /**
     Get the rgb values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit rgb string.
     */
    func toRGB8BitString() -> String {
        let RGB = toRGBAComponents()
        let red = Int(round(RGB.r * 255))
        let green = Int(round(RGB.g * 255))
        let blue = Int(round(RGB.b * 255))
        let rgbString = NSString(format: "rgb(%d, %d, %d)", red, green, blue)
        return rgbString as String
    }

    // HSB
    // swiftlint:disable large_tuple
    public final func toHSBComponents() -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0

        guard let rgbaColor = usingColorSpace(Defaults[.colorSpace]) else {
            fatalError("Could not convert color to RGBA.")
        }

        if toHexString() == NSColor.black.toHexString() {
            return (0.0, 0.0, 0.0)
        } else if toHexString() == NSColor.white.toHexString() {
            return (0.0, 0.0, 1.0)
        }

        rgbaColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)

        return (h: h, s: s, b: b)
    }

    public final func toHSLComponents() -> (h: CGFloat, s: CGFloat, l: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var l: CGFloat = 0.0

        let RGB = toRGBAComponents()
        let r = RGB.r
        let g = RGB.g
        let b = RGB.b

        if toHexString() == NSColor.black.toHexString() {
            return (0.0, 0.0, 0.0)
        } else if toHexString() == NSColor.white.toHexString() {
            return (0.0, 0.0, 1.0)
        }

        let min = Swift.min(Swift.min(r, g), b)
        let max = Swift.max(Swift.max(r, g), b)
        let delta = max - min

        if max == min {
            h = 0
        } else if r == max {
            h = (g - b) / delta
        } else if g == max {
            h = 2 + (b - r) / delta
        } else {
            h = 4 + (r - g) / delta
        }

        h = Swift.min(h * 60, 360)

        if h < 0 {
            h += 360
        }

        h /= 360

        l = (min + max) / 2

        if max == min {
            s = 0
        } else if l <= 0.5 {
            s = delta / (max + min)
        } else {
            s = delta / (2 - max - min)
        }

        return (h: h, s: s, l: l)
    }

    // swiftlint:enable large_tuple

    /**
     Get the hsb values of this color.

     - returns: An NSColor as an hsb string.
     */
    func toHSBString() -> String {
        let HSB = toHSBComponents()
        let hue = HSB.h
        let saturation = HSB.s
        let brightness = HSB.b
        let hsbString = NSString(format: "hsb(%f, %f, %f)", hue, saturation, brightness)
        return hsbString as String
    }

    /**
     Get the hsb values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit hsb string.
     */
    func toHSB8BitString() -> String {
        let HSB = toHSBComponents()
        let hue = Int(round(HSB.h * 360))
        let saturation = Int(round(HSB.s * 100))
        let brightness = Int(round(HSB.b * 100))
        let hsbString = NSString(format: "hsb(%d, %d, %d)", hue, saturation, brightness)
        return hsbString as String
    }

    // HSL

    /**
     Get the hsl values of this color.

     - returns: An NSColor as an hsl string.
     */
    func toHSLString() -> String {
        let HSL = toHSLComponents()
        let hue = HSL.h
        let saturation = HSL.s
        let lightness = HSL.l
        let hslString = NSString(format: "hsl(%f, %f, %f)", hue, saturation, lightness)
        return hslString as String
    }

    /**
     Get the hsl values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit hsl string.
     */
    func toHSL8BitString() -> String {
        let HSL = toHSLComponents()
        let hue = Int(round(HSL.h * 360))
        let saturation = Int(round(HSL.s * 100))
        let lightness = Int(round(HSL.l * 100))
        let hslString = NSString(format: "hsl(%d, %d, %d)", hue, saturation, lightness)
        return hslString as String
    }

    /**
     Returns hex and string formats of each color

     - returns: A string of the color depending on the provided format.
     */
    func toFormat(format: ColorFormat) -> String {
        switch format {
        case .hex:
            return toHexString()
        case .rgb:
            return toRGB8BitString()
        case .hsb:
            return toHSB8BitString()
        case .hsl:
            return toHSL8BitString()
        }
    }

    func getUIColor() -> (Color) {
        return luminance < 0.5 ? Color.white : Color.black
    }

    func getUIColor() -> (NSColor) {
        return luminance < 0.5 ? NSColor.white : NSColor.black
    }
}
