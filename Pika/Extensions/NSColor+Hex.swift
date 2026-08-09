import Cocoa
import Defaults

extension NSColor {
    /// Parse a hex string into a colour, or `nil` if it isn't valid hex.
    ///
    /// Accepts 3 or 6 hex digits, case-insensitive, with or without a leading `#`.
    /// This is the one validating hex parser — unlike the `init(hex:)` convenience
    /// init it never falls back to a colour, so callers (live editing, etc.) can tell
    /// valid input from invalid. Builds in `colorSpace` so a value read back via
    /// `toHexString()` (which reads `Defaults[.colorSpace]`) round-trips exactly.
    static func fromHex(
        _ hex: String,
        in colorSpace: NSColorSpace = Defaults[.colorSpace],
        alpha: CGFloat = 1
    ) -> NSColor? {
        var stripped = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard stripped.count == 3 || stripped.count == 6,
              stripped.allSatisfy(\.isHexDigit) else { return nil }

        if stripped.count == 3 {
            stripped = stripped.map { "\($0)\($0)" }.joined()
        }

        var rgb: UInt64 = 0
        guard Scanner(string: stripped).scanHexInt64(&rgb) else { return nil }

        let components: [CGFloat] = [
            CGFloat((rgb >> 16) & 0xFF) / 255,
            CGFloat((rgb >> 8) & 0xFF) / 255,
            CGFloat(rgb & 0xFF) / 255,
            alpha,
        ]
        return NSColor(colorSpace: colorSpace, components: components, count: 4)
    }

    func roundToHex(_ value: CGFloat) -> UInt32 {
        guard value > 0 else { return 0 }
        let rounded: CGFloat = round(value * 255.0)
        return UInt32(rounded)
    }

    func toHex() -> UInt32 {
        let rgba = toRGBAComponents()
        return roundToHex(rgba.r) << 16 | roundToHex(rgba.g) << 8 | roundToHex(rgba.b)
    }

    func toHexString(style: CopyFormat = .css) -> String {
        String(format: style == .css ? "#%06x" : "%06x", toHex())
    }
}
