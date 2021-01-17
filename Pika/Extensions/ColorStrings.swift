import Cocoa

extension NSColor {
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

    /**
     Get the hsl values of this color.

     - returns: An NSColor as an hsl string.
     */
    func toHSLString() -> String {
        let HSL = toHSLComponents()
        let hue = HSL.h / 360
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
        let hue = Int(round(HSL.h))
        let saturation = Int(round(HSL.s * 100))
        let lightness = Int(round(HSL.l * 100))
        let hslString = NSString(format: "hsl(%d, %d, %d)", hue, saturation, lightness)
        return hslString as String
    }

    /**
     Returns hex and string formats of each colour

     - returns: A string of the colour depending on the provided format.
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
}
