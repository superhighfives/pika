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
    // hex round-trips exactly.
    private static func colorFromHex(_ hex: String) -> NSColor {
        let fallback = NSColor.black.usingColorSpace(Defaults[.colorSpace]) ?? .black
        let stripped = hex.replacingOccurrences(of: "#", with: "")
        guard stripped.count == 6 else { return fallback }
        let scanner = Scanner(string: stripped)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return fallback }
        let components: [CGFloat] = [
            CGFloat((rgb >> 16) & 0xFF) / 255,
            CGFloat((rgb >> 8) & 0xFF) / 255,
            CGFloat(rgb & 0xFF) / 255,
            1.0,
        ]
        return NSColor(colorSpace: Defaults[.colorSpace], components: components, count: 4)
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
