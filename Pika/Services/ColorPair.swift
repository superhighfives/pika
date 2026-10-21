import Cocoa
import Defaults

struct ColorPair: Codable, Identifiable, Equatable {
    let id: UUID
    /// Each colour's hex as read when it was saved, in the colour space set then. Only the
    /// fallback for entries saved before 2.0.2, which have no components.
    let foregroundHex: String
    let backgroundHex: String
    let date: Date
    /// Each colour as extended sRGB components (red, green, blue), so an entry reads back as
    /// exactly the colour saved: changing the colour space setting doesn't move it, and a colour
    /// outside the space survives a restore. `nil` for entries saved before 2.0.2.
    var foregroundComponents: [Double]?
    var backgroundComponents: [Double]?

    init(
        id: UUID, foregroundHex: String, backgroundHex: String, date: Date,
        foregroundComponents: [Double]? = nil, backgroundComponents: [Double]? = nil
    ) {
        self.id = id
        self.foregroundHex = foregroundHex
        self.backgroundHex = backgroundHex
        self.date = date
        self.foregroundComponents = foregroundComponents
        self.backgroundComponents = backgroundComponents
    }

    init(id: UUID = UUID(), foreground: NSColor, background: NSColor, date: Date = Date()) {
        self.init(
            id: id,
            foregroundHex: foreground.toHexString(),
            backgroundHex: background.toHexString(),
            date: date,
            foregroundComponents: Self.components(of: foreground),
            backgroundComponents: Self.components(of: background)
        )
    }

    var foregroundColor: NSColor { Self.color(foregroundComponents, hex: foregroundHex) }
    var backgroundColor: NSColor { Self.color(backgroundComponents, hex: backgroundHex) }

    /// The same entry with foreground and background exchanged.
    var swapped: ColorPair {
        ColorPair(
            id: id, foregroundHex: backgroundHex, backgroundHex: foregroundHex, date: date,
            foregroundComponents: backgroundComponents, backgroundComponents: foregroundComponents
        )
    }

    /// An entry saved before 2.0.2 with its colours fixed as they read in `space`, the space its
    /// hex was written in. Entries that already have components are returned unchanged.
    func pinned(readingHexIn space: NSColorSpace) -> ColorPair {
        guard foregroundComponents == nil || backgroundComponents == nil else { return self }
        func pin(_ hex: String) -> [Double]? {
            NSColor.fromHex(hex, in: space).flatMap(Self.components(of:))
        }
        return ColorPair(
            id: id, foregroundHex: foregroundHex, backgroundHex: backgroundHex, date: date,
            foregroundComponents: foregroundComponents ?? pin(foregroundHex),
            backgroundComponents: backgroundComponents ?? pin(backgroundHex)
        )
    }

    private static func components(of color: NSColor) -> [Double]? {
        guard let extended = color.usingColorSpace(.extendedSRGB) else { return nil }
        return [extended.redComponent, extended.greenComponent, extended.blueComponent].map(Double.init)
    }

    private static func color(_ components: [Double]?, hex: String) -> NSColor {
        if let components, components.count == 3 {
            return NSColor(colorSpace: .extendedSRGB, components: components.map { CGFloat($0) } + [1], count: 4)
        }
        return colorFromHex(hex)
    }

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

    /// Equal when both colours read as the same hex in the current colour space, so two entries
    /// count as the same pick whichever space each was saved in.
    static func == (lhs: ColorPair, rhs: ColorPair) -> Bool {
        lhs.foregroundColor.toHex() == rhs.foregroundColor.toHex()
            && lhs.backgroundColor.toHex() == rhs.backgroundColor.toHex()
    }

    /// Whether this entry holds these two colours, as read in the current colour space.
    func holds(foreground: NSColor, background: NSColor) -> Bool {
        foregroundColor.toHex() == foreground.toHex() && backgroundColor.toHex() == background.toHex()
    }
}

struct Palette: Codable, Identifiable {
    let id: UUID
    var name: String?
    var pairs: [ColorPair]
    let createdAt: Date

    var isAutoHistory: Bool { name == nil }
}
