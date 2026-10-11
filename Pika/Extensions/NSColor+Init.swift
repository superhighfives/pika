import Cocoa

extension NSColor {
    // r, g, b, a are the public parameter labels for this init (NSColor(r:g:b:a:)) and cannot be renamed.
    // swiftlint:disable:next identifier_name
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (r > 1) || (g > 1) || (b > 1) {
            self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
        } else {
            self.init(red: r, green: g, blue: b, alpha: a)
        }
    }

    /**
     Create an NSColor with a string hex value.

     - parameter hex:     The hex color, i.e. "FF0072" or "#FF0072".
     - parameter alpha:   The opacity of the color, value between [0,1]. Optional. Default: 1

     Invalid input falls back to black rather than crashing — this is fed remote and
     user-facing strings (URL schemes, colour lists). Callers that need to *reject*
     invalid input should use the failable `NSColor.fromHex(_:)` instead.
     */
    convenience init(hex: String, alpha: CGFloat = 1) {
        let parsed = NSColor.fromHex(hex, in: .sRGB, alpha: alpha)
            ?? NSColor(colorSpace: .sRGB, components: [0, 0, 0, alpha], count: 4)
        // `parsed` is already in sRGB, so its components read back without conversion.
        self.init(
            srgbRed: parsed.redComponent,
            green: parsed.greenComponent,
            blue: parsed.blueComponent,
            alpha: parsed.alphaComponent
        )
    }
}
