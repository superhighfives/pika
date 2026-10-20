import Cocoa
import Defaults

/// What the colour space setting can be: a fixed space, or whichever display a pick lands on.
enum ColorSpaceOption: Hashable {
    case space(NSColorSpace)
    case matchDisplay
}

/// The colour space Pika reads hex, RGB, HSB, HSL and OpenGL values in.
///
/// `Defaults[.colorSpace]` stays the one space every formatter reads. "Match display" is a flag
/// beside it: while it's on, `colorSpace` is kept pointing at the profile of the display being
/// picked on, so formatters and their observers need no changes.
enum ColorSpacePreference {
    static var current: ColorSpaceOption {
        Defaults[.colorSpaceMatchesDisplay] ? .matchDisplay : .space(Defaults[.colorSpace])
    }

    static func select(_ option: ColorSpaceOption) {
        switch option {
        case let .space(space):
            Defaults[.colorSpaceMatchesDisplay] = false
            if Defaults[.colorSpace] != space { Defaults[.colorSpace] = space }
        case .matchDisplay:
            Defaults[.colorSpaceMatchesDisplay] = true
            followDisplay(NSScreen.main)
        }
        // The system colour panel holds its own copy of the space; reopening picks up the new one.
        NSColorPanel.shared.close()
    }

    /// sRGB and Display P3 are what nearly everyone works in, so the readout doesn't label them.
    /// Anything else is labelled, because a hex in it won't match one copied from the web.
    static func isCommon(_ space: NSColorSpace) -> Bool {
        space == .sRGB || space == .displayP3
    }

    /// While matching the display, adopt `screen`'s profile. Called on launch, when displays
    /// change, and as a pick commits, with the screen it was made on.
    static func followDisplay(_ screen: NSScreen?) {
        guard Defaults[.colorSpaceMatchesDisplay],
              let space = (screen ?? NSScreen.main)?.colorSpace
        else { return }
        if Defaults[.colorSpace] != space { Defaults[.colorSpace] = space }
    }

    static func screen(containing point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }

    /// A space's name for labels: "sRGB" rather than macOS's "sRGB IEC61966-2.1".
    static func name(of space: NSColorSpace) -> String {
        space == .sRGB ? "sRGB" : space.localizedName ?? ""
    }

    /// The display profile "Match display" would use right now, for labels.
    static var displaySpaceName: String? {
        NSScreen.main?.colorSpace?.localizedName
    }

    static func prepareOnLaunch() {
        migrateDisplayProfileChoice()
        if Defaults[.colorSpaceMatchesDisplay] {
            followDisplay(NSScreen.main)
        } else if !isCommon(Defaults[.colorSpace]),
                  !NSColorSpace.availableColorSpaces(with: .rgb).contains(Defaults[.colorSpace])
        {
            // A profile that has gone (a display's, or an uninstalled one).
            Defaults[.colorSpace] = .sRGB
        }
    }

    /// Before 2.0.2 the default was the main display's profile, offered as "System default".
    /// Anyone who never chose a space has no stored value, and now gets the new sRGB default.
    /// Anyone who did choose a display's profile gets "Match display", which follows the screen
    /// they pick on instead of keeping a snapshot of whichever was main at the time.
    private static func migrateDisplayProfileChoice() {
        guard !Defaults[.colorSpaceMigrated] else { return }
        Defaults[.colorSpaceMigrated] = true
        guard UserDefaults.standard.object(forKey: Defaults.Keys.colorSpace.name) != nil else {
            // History and palettes keep hex, read in the current space. Theirs was written in
            // the old default, so re-express it in sRGB to keep the same colours.
            if let previous = NSScreen.main?.colorSpace, previous != .sRGB {
                reexpressStoredColors(from: previous, to: .sRGB)
            }
            return
        }
        let stored = Defaults[.colorSpace]
        if !isCommon(stored), NSScreen.screens.contains(where: { $0.colorSpace == stored }) {
            Defaults[.colorSpaceMatchesDisplay] = true
        }
    }

    /// Rewrites every stored hex (history, palettes, undo and redo) from one space to another,
    /// so the colours they describe stay the same.
    static func reexpressStoredColors(from old: NSColorSpace, to new: NSColorSpace) {
        func convert(_ hex: String) -> String {
            guard let color = NSColor.fromHex(hex, in: old) else { return hex }
            let digits = String(format: "%06x", color.toHex(in: new))
            return hex.hasPrefix("#") ? "#" + digits : digits
        }
        func convert(_ pair: ColorPair) -> ColorPair {
            ColorPair(
                id: pair.id,
                foregroundHex: convert(pair.foregroundHex),
                backgroundHex: convert(pair.backgroundHex),
                date: pair.date
            )
        }
        Defaults[.palettes] = Defaults[.palettes].map { palette in
            var palette = palette
            palette.pairs = palette.pairs.map(convert)
            return palette
        }
        Defaults[.colorHistory] = Defaults[.colorHistory].map(convert)
        Defaults[.undoStack] = Defaults[.undoStack].map { $0.map(convert) }
        Defaults[.redoStack] = Defaults[.redoStack].map { $0.map(convert) }
    }
}

/// How a picked colour reads in one colour space, against the hex the user expected.
struct ColorSpaceMatch: Equatable {
    let space: NSColorSpace
    let hex: UInt32
    /// The largest difference in any one 8-bit channel.
    let distance: Int

    var isMatch: Bool { distance <= ColorSpaceMatcher.tolerance }
}

/// Finds the colour space that reads a picked colour back as the hex the user expected.
///
/// The app showing the colour turned its hex into display pixels through some colour space, and
/// Pika captured those pixels. Reading the capture in that same space recovers the hex, so the
/// candidate that lands closest is the space the source app used.
enum ColorSpaceMatcher {
    /// Display output and capture are each 8-bit, so a round trip can land a step or two away.
    static let tolerance = 2

    static func candidates(screens: [NSScreen] = NSScreen.screens) -> [NSColorSpace] {
        var spaces: [NSColorSpace] = [.sRGB, .displayP3]
        for space in screens.compactMap(\.colorSpace) where !spaces.contains(space) {
            spaces.append(space)
        }
        if !spaces.contains(.adobeRGB1998) { spaces.append(.adobeRGB1998) }
        return spaces
    }

    /// Every candidate's reading, closest first. Ties keep candidate order, so sRGB wins one.
    static func compare(
        _ color: NSColor, expected: UInt32, in spaces: [NSColorSpace] = candidates()
    ) -> [ColorSpaceMatch] {
        let matches = spaces.enumerated().map { index, space in
            let hex = color.toHex(in: space)
            return (index, ColorSpaceMatch(space: space, hex: hex, distance: channelDistance(hex, expected)))
        }
        return matches
            .sorted { ($0.1.distance, $0.0) < ($1.1.distance, $1.0) }
            .map(\.1)
    }

    static func channelDistance(_ lhs: UInt32, _ rhs: UInt32) -> Int {
        [16, 8, 0].map { shift in
            abs(Int((lhs >> shift) & 0xFF) - Int((rhs >> shift) & 0xFF))
        }.max() ?? 0
    }
}
