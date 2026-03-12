import Cocoa
import Defaults

struct ColorPair: Codable, Identifiable, Equatable {
    let id: UUID
    let foregroundHex: String
    let backgroundHex: String
    let date: Date

    var foregroundColor: NSColor { Self.colorFromHex(foregroundHex) }
    var backgroundColor: NSColor { Self.colorFromHex(backgroundHex) }

    // Reconstructs the color in sRGB. History hex values are stored as sRGB,
    // so decoding them in sRGB keeps history stable regardless of the current
    // Defaults[.colorSpace] preference.
    private static func colorFromHex(_ hex: String) -> NSColor {
        let fallback = NSColor.black.usingColorSpace(.sRGB) ?? .black
        let h = hex.replacingOccurrences(of: "#", with: "")
        guard h.count == 6 else { return fallback }
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return fallback }
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }

    static let maxHistory = 20

    static func == (lhs: ColorPair, rhs: ColorPair) -> Bool {
        lhs.foregroundHex == rhs.foregroundHex && lhs.backgroundHex == rhs.backgroundHex
    }
}
