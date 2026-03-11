import Cocoa

extension NSColor {
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
