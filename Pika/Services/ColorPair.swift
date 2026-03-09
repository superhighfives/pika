import Cocoa

struct ColorPair: Codable, Identifiable, Equatable {
    let id: UUID
    let foregroundHex: String
    let backgroundHex: String
    let date: Date

    var foregroundColor: NSColor { NSColor(hex: foregroundHex) }
    var backgroundColor: NSColor { NSColor(hex: backgroundHex) }

    static let maxHistory = 20

    static func == (lhs: ColorPair, rhs: ColorPair) -> Bool {
        lhs.foregroundHex == rhs.foregroundHex && lhs.backgroundHex == rhs.backgroundHex
    }
}
