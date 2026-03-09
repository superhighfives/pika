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
    // reads from. This makes set() a no-op (colorSpace → colorSpace), so the stored
    // hex round-trips exactly and isActivePair comparison always holds.
    private static func colorFromHex(_ hex: String) -> NSColor {
        let h = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
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
