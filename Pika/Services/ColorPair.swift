import Cocoa
import Defaults

struct ColorPair: Codable, Identifiable, Equatable {
    let id: UUID
    let foregroundHex: String
    let backgroundHex: String
    let date: Date

    var foregroundColor: NSColor { Self.colorFromHex(foregroundHex) }
    var backgroundColor: NSColor { Self.colorFromHex(backgroundHex) }

    // Reconstructs the color in Defaults[.colorSpace] — the same space toHexString()
    // reads from. This makes set() a no-op (colorSpace → colorSpace) so the stored
    // hex round-trips exactly. Stored hex is always 6 digits (from toHexString), so
    // anything else is treated as corrupt and falls back to black.
    private static func colorFromHex(_ hex: String) -> NSColor {
        let fallback = NSColor.black.usingColorSpace(Defaults[.colorSpace]) ?? .black
        guard hex.replacingOccurrences(of: "#", with: "").count == 6 else { return fallback }
        return NSColor.fromHex(hex) ?? fallback
    }

    static let maxHistory = 20

    static func == (lhs: ColorPair, rhs: ColorPair) -> Bool {
        lhs.foregroundHex == rhs.foregroundHex && lhs.backgroundHex == rhs.backgroundHex
    }
}

struct Palette: Codable, Identifiable {
    let id: UUID
    var name: String?
    var pairs: [ColorPair]
    let createdAt: Date

    var isAutoHistory: Bool { name == nil }
}
