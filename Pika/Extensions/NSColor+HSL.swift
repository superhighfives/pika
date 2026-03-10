import Cocoa
import Defaults

// swiftlint:disable identifier_name

extension NSColor {
    /*
     * HSB
     */

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
        h = h.truncatingRemainder(dividingBy: 1.0)

        return (h: h, s: s, b: b)
    }

    /**
     Get the hsb values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit hsb string.
     */
    func toHSBString(style: CopyFormat = .css) -> String {
        let HSB = toHSBComponents()
        let hue = Int(round(HSB.h * 360))
        let saturation = Int(round(HSB.s * 100))
        let brightness = Int(round(HSB.b * 100))

        let hsbString: String
        switch style {
        case .css:
            hsbString = String(format: "hsb(%d, %d%%, %d%%)", hue, saturation, brightness)
        case .design:
            hsbString = String(format: "hsb(%d, %d, %d)", hue, saturation, brightness)
        case .swiftUI:
            hsbString = String(format: "Color(hue: %.5g, saturation: %.5g, brightness: %.5g)", HSB.h, HSB.s, HSB.b)
        case .unformatted:
            hsbString = String(format: "%d, %d, %d", hue, saturation, brightness)
        }
        return hsbString
    }

    /*
     * HSL
     */

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

    /**
     Get the hsl values of this color in 8-bit format.

     - returns: An NSColor as an 8-bit hsl string.
     */
    func toHSLString(style: CopyFormat = .css) -> String {
        let HSL = toHSLComponents()
        let hue = Int(round(HSL.h * 360))
        let saturation = Int(round(HSL.s * 100))
        let lightness = Int(round(HSL.l * 100))

        let formatString: NSString
        switch style {
        case .css:
            formatString = "hsl(%d, %d%%, %d%%)"
        case .design, .swiftUI:
            formatString = "hsl(%d, %d, %d)"
        case .unformatted:
            formatString = "%d, %d, %d"
        }

        let hslString = NSString(format: formatString, hue, saturation, lightness)
        return hslString as String
    }
}

// swiftlint:enable identifier_name
