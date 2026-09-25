import Cocoa
import Defaults

// swiftlint:disable identifier_name
// identifier_name is disabled because color science math uses conventional single-letter
// variable names (h, s, b, l, r, g) that would be misleading if renamed.

public struct HSBComponents { let h, s, b: CGFloat }
public struct HSLComponents { let h, s, l: CGFloat }

extension NSColor {
    /*
     * HSB
     */

    public final func toHSBComponents() -> HSBComponents {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0

        guard let rgbaColor = usingColorSpace(Defaults[.colorSpace]) else {
            fatalError("Could not convert color to RGBA.")
        }

        if toHexString() == NSColor.black.toHexString() {
            return HSBComponents(h: 0.0, s: 0.0, b: 0.0)
        } else if toHexString() == NSColor.white.toHexString() {
            return HSBComponents(h: 0.0, s: 0.0, b: 1.0)
        }

        rgbaColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        h = h.truncatingRemainder(dividingBy: 1.0)

        return HSBComponents(h: h, s: s, b: b)
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

    public final func toHSLComponents() -> HSLComponents {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var l: CGFloat = 0.0

        let RGB = toRGBAComponents()
        let r = RGB.r
        let g = RGB.g
        let b = RGB.b

        if toHexString() == NSColor.black.toHexString() {
            return HSLComponents(h: 0.0, s: 0.0, l: 0.0)
        } else if toHexString() == NSColor.white.toHexString() {
            return HSLComponents(h: 0.0, s: 0.0, l: 1.0)
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

        return HSLComponents(h: h, s: s, l: l)
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

    /*
     * Inverses (string/component → colour)
     *
     * These are the inverses of `toHSBComponents` / `toHSLComponents` and take the same
     * normalised units (h, s, b/l all in 0…1). They build the colour directly in `colorSpace`
     * — the same space the forward conversions read from — so a decompose→recompose round-trip
     * lands on the same colour (±1 in the display units, from integer rounding).
     */

    /// Build a colour from HSB/HSV components (all in 0…1), in `colorSpace`.
    static func fromHSB(
        h: CGFloat, s: CGFloat, b: CGFloat,
        in colorSpace: NSColorSpace = Defaults[.colorSpace]
    ) -> NSColor {
        let v = b
        guard s > 0 else {
            return NSColor(colorSpace: colorSpace, components: [v, v, v, 1], count: 4)
        }

        let hue = (h.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1) * 6
        let i = floor(hue)
        let f = hue - i
        let p = v * (1 - s)
        let q = v * (1 - s * f)
        let t = v * (1 - s * (1 - f))

        let r, g, bl: CGFloat
        switch Int(i) % 6 {
        case 0: (r, g, bl) = (v, t, p)
        case 1: (r, g, bl) = (q, v, p)
        case 2: (r, g, bl) = (p, v, t)
        case 3: (r, g, bl) = (p, q, v)
        case 4: (r, g, bl) = (t, p, v)
        default: (r, g, bl) = (v, p, q)
        }
        return NSColor(colorSpace: colorSpace, components: [r, g, bl, 1], count: 4)
    }

    /// Build a colour from HSL components (all in 0…1), in `colorSpace`.
    static func fromHSL(
        h: CGFloat, s: CGFloat, l: CGFloat,
        in colorSpace: NSColorSpace = Defaults[.colorSpace]
    ) -> NSColor {
        guard s > 0 else {
            return NSColor(colorSpace: colorSpace, components: [l, l, l, 1], count: 4)
        }

        func hue2rgb(_ p: CGFloat, _ q: CGFloat, _ t: CGFloat) -> CGFloat {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        let r = hue2rgb(p, q, h + 1 / 3)
        let g = hue2rgb(p, q, h)
        let b = hue2rgb(p, q, h - 1 / 3)
        return NSColor(colorSpace: colorSpace, components: [r, g, b, 1], count: 4)
    }
}

// swiftlint:enable identifier_name
