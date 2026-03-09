import Cocoa

struct ColorPair: Codable, Identifiable, Equatable {
    let id: UUID
    let foregroundHex: String
    let backgroundHex: String
    let date: Date

    var foregroundColor: NSColor { Self.colorFromHex(foregroundHex) }
    var backgroundColor: NSColor { Self.colorFromHex(backgroundHex) }

    // Uses sRGB explicitly so the round-trip through set() (which converts to
    // Defaults[.colorSpace]) and toHexString() (which reads in Defaults[.colorSpace])
    // produces the same hex as the stored value.
    private static func colorFromHex(_ hex: String) -> NSColor {
        var h = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        return NSColor(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    static let maxHistory = 20

    static func == (lhs: ColorPair, rhs: ColorPair) -> Bool {
        lhs.foregroundHex == rhs.foregroundHex && lhs.backgroundHex == rhs.backgroundHex
    }
}
