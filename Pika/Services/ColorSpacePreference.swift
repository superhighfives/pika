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

    /// Whether `space` is Display P3 in all but name. Apple's display profiles ("Studio Display",
    /// "Color LCD") describe P3 colorimetrically but don't compare equal to `.displayP3`, so on a
    /// P3 screen "Match display" would otherwise copy CSS as a bare hex. Measured: Studio Display
    /// lands P3's primaries, white and mid-tones exactly; a QD-OLED's wider profile is 76 steps
    /// out, and cinema DCI-P3 (another white point and gamma) 68. Two steps of slack for a
    /// per-panel calibration; copies convert to true P3, so the slack never skews the output.
    static func isDisplayP3Equivalent(_ space: NSColorSpace) -> Bool {
        if space == .displayP3 { return true }
        guard let extendedP3 = CGColorSpace(name: CGColorSpace.extendedDisplayP3)
            .flatMap(NSColorSpace.init(cgColorSpace:))
        else { return false }
        let probes: [[CGFloat]] = [[1, 0, 0], [0, 1, 0], [0, 0, 1], [1, 1, 1], [0.5, 0.5, 0.5], [0.2, 0.6, 0.9]]
        return probes.allSatisfy { probe in
            guard let read = NSColor(colorSpace: space, components: probe + [1], count: 4)
                .usingColorSpace(extendedP3)
            else { return false }
            return zip([read.redComponent, read.greenComponent, read.blueComponent], probe)
                .allSatisfy { abs($0 - $1) * 255 <= CGFloat(ColorSpaceMatcher.tolerance) }
        }
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

    /// Before 2.0.2 the default was the main display's profile, offered as "System default", and
    /// history kept only hex, read in whatever space was set. Once, on the first launch of 2.0.2:
    /// - every stored entry is pinned to the colour it shows now, read in the space its hex was
    ///   written in, so neither this change nor any later one moves it;
    /// - anyone who never chose a space then gets the new sRGB default;
    /// - anyone who chose a display's profile gets "Match display", which follows the screen they
    ///   pick on instead of keeping a snapshot of whichever was main at the time.
    private static func migrateDisplayProfileChoice() {
        guard !Defaults[.colorSpaceMigrated] else { return }
        Defaults[.colorSpaceMigrated] = true
        // A stored space that doesn't decode reads as the key's default, which was the main
        // display's profile before 2.0.2 (and is sRGB now), so it counts as nothing chosen.
        let chosen = storedColorSpace()
        // With nothing chosen, the hex was written in the old default.
        let written = chosen ?? NSScreen.main?.colorSpace ?? .sRGB
        pinStoredColors(readingHexIn: written)
        if chosen != nil, !isCommon(written), NSScreen.screens.contains(where: { $0.colorSpace == written }) {
            Defaults[.colorSpaceMatchesDisplay] = true
        }
    }

    /// Whether `key` has been written. `UserDefaults.object(forKey:)` can't say: `Defaults`
    /// registers each key's default, so it returns that for a key nobody ever set.
    static func isPersisted(_ key: String) -> Bool {
        guard let domain = Bundle.main.bundleIdentifier else { return false }
        return UserDefaults.standard.persistentDomain(forName: domain)?[key] != nil
    }

    /// The colour space actually stored, or `nil` when none is, or it doesn't decode. `Defaults`
    /// returns the key's default in both cases, so it can't tell them from a choice of sRGB.
    static func storedColorSpace() -> NSColorSpace? {
        guard let domain = Bundle.main.bundleIdentifier,
              let data = UserDefaults.standard.persistentDomain(forName: domain)?[Defaults.Keys.colorSpace.name] as? Data
        else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColorSpace.self, from: data)
    }

    /// Gives every stored entry (history, palettes, undo and redo) components, read from its hex
    /// in `space`. Entries that already have them are left alone.
    static func pinStoredColors(readingHexIn space: NSColorSpace) {
        let pin = { (pair: ColorPair) in pair.pinned(readingHexIn: space) }
        // Only keys that exist: writing a default back would create one that wasn't there.
        func isStored(_ key: Defaults.Keys) -> Bool { isPersisted(key.name) }
        if isStored(.palettes) {
            Defaults[.palettes] = Defaults[.palettes].map { palette in
                var palette = palette
                palette.pairs = palette.pairs.map(pin)
                return palette
            }
        }
        if isStored(.colorHistory) { Defaults[.colorHistory] = Defaults[.colorHistory].map(pin) }
        if isStored(.undoStack) { Defaults[.undoStack] = Defaults[.undoStack].map { $0.map(pin) } }
        if isStored(.redoStack) { Defaults[.redoStack] = Defaults[.redoStack].map { $0.map(pin) } }
    }
}

/// A colour value the user typed, in any of Pika's formats, read without a colour space so it
/// can be rebuilt in each candidate one.
struct ExpectedColor: Equatable {
    let format: ColorFormat
    let style: CopyFormat
    /// The numbers as typed (for hex, the six digits).
    let values: [String]

    /// Lab and OKLCH describe a colour the same way in every colour space.
    var isAbsolute: Bool { format == .lab || format == .oklch }

    /// Reads `text`, detecting the format from its own shape (`#…`, `rgb(…)`, `hsl(…)`,
    /// `Color(red: …)`), and using `fallback` for bare numbers. `nil` if it doesn't parse.
    static func parse(_ text: String, fallback: ColorFormat) -> ExpectedColor? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard !lower.isEmpty else { return nil }
        let (format, style) = detect(lower) ?? (fallback, .css)
        if format == .hex {
            let digits = lower.hasPrefix("#") ? String(lower.dropFirst()) : lower
            guard NSColor.fromHex(digits, in: .sRGB) != nil else { return nil }
            let full = digits.count == 3 ? digits.map { "\($0)\($0)" }.joined() : digits
            return ExpectedColor(format: .hex, style: style, values: [full])
        }
        let numbers = numbers(in: lower)
        guard numbers.count >= 3 else { return nil }
        let expected = ExpectedColor(format: format, style: style, values: Array(numbers.prefix(3)))
        return expected.color(in: .sRGB) == nil ? nil : expected
    }

    /// The colour these numbers make in `space` (or, for Lab and OKLCH, in any space).
    func color(in space: NSColorSpace) -> NSColor? {
        format.recompose(values, style: style, in: space)
    }

    private static func detect(_ text: String) -> (ColorFormat, CopyFormat)? {
        if text.hasPrefix("#") { return (.hex, .css) }
        if text.hasPrefix("color(red") { return (.rgb, .swiftUI) }
        if text.hasPrefix("color(hue") { return (.hsb, .swiftUI) }
        let prefixes: [(String, ColorFormat)] = [
            ("oklch(", .oklch), ("lab(", .lab), ("hsl(", .hsl), ("hsb(", .hsb), ("hsv(", .hsb),
            ("rgba(", .opengl), ("rgb(", .rgb),
        ]
        if let match = prefixes.first(where: { text.hasPrefix($0.0) }) { return (match.1, .css) }
        // Six (or three) hex digits on their own.
        if [3, 6].contains(text.count), text.allSatisfy(\.isHexDigit), text.contains(where: \.isLetter) {
            return (.hex, .css)
        }
        return nil
    }

    private static func numbers(in text: String) -> [String] {
        let pattern = try? NSRegularExpression(pattern: "-?\\d*\\.?\\d+")
        let range = NSRange(text.startIndex..., in: text)
        return pattern?.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        } ?? []
    }
}

/// How a picked colour reads in one colour space, against the value the user expected.
struct ColorSpaceMatch: Equatable {
    let space: NSColorSpace
    /// The picked colour's hex in `space`.
    let hex: UInt32
    /// The picked colour in `space`, written in the expected value's own format.
    let reading: String
    /// The largest difference in any one 8-bit channel between the expected colour and the pick.
    let distance: Int
    /// The reading's numbers are the typed numbers.
    let isExact: Bool
    /// Every number is within one step of the precision typed (or shown).
    let isWithinRounding: Bool

    var isMatch: Bool { isExact || isWithinRounding || distance <= ColorSpaceMatcher.tolerance }
}

/// Finds the colour space that reads a picked colour back as the value the user expected.
///
/// The app showing the colour turned its value into display pixels through some colour space,
/// and Pika captured those pixels. Reading the capture in that same space recovers the value, so
/// the candidate that lands closest is the space the source app used. Lab and OKLCH don't depend
/// on a space, so for them there's one reading, and only whether it matches.
enum ColorSpaceMatcher {
    /// Display output and capture are each 8-bit, so a round trip can land a step or two away.
    static let tolerance = 2

    static func candidates(screens: [NSScreen] = NSScreen.screens) -> [NSColorSpace] {
        var spaces: [NSColorSpace] = [.sRGB, .displayP3]
        // A P3-equivalent screen profile would only repeat the Display P3 row.
        for space in screens.compactMap(\.colorSpace)
            where !spaces.contains(space) && !ColorSpacePreference.isDisplayP3Equivalent(space)
        {
            spaces.append(space)
        }
        if !spaces.contains(.adobeRGB1998) { spaces.append(.adobeRGB1998) }
        return spaces
    }

    /// Every candidate's reading of a hex, closest first.
    static func compare(
        _ color: NSColor, expected: UInt32, in spaces: [NSColorSpace] = candidates()
    ) -> [ColorSpaceMatch] {
        let value = ExpectedColor(format: .hex, style: .css, values: [String(format: "%06x", expected)])
        return compare(color, expected: value, in: spaces)
    }

    /// Every candidate's reading, closest first. Ties keep candidate order, so sRGB wins one. For
    /// Lab and OKLCH, a single reading (in sRGB, which makes no difference to them).
    static func compare(
        _ color: NSColor, expected: ExpectedColor, in spaces: [NSColorSpace] = candidates()
    ) -> [ColorSpaceMatch] {
        let spaces = expected.isAbsolute ? [NSColorSpace.sRGB] : spaces
        let matches = spaces.enumerated().compactMap { index, space -> (Int, ColorSpaceMatch)? in
            guard let target = expected.color(in: space) else { return nil }
            let hex = color.toHex(in: space)
            let reading = expected.format.decompose(color, style: expected.style, in: space)
            let (exact, close) = compareNumbers(expected, reading.values)
            return (index, ColorSpaceMatch(
                space: space, hex: hex, reading: reading.joined(),
                distance: channelDistance(hex, target.toHex(in: space)),
                isExact: exact, isWithinRounding: close
            ))
        }
        return matches
            .sorted { ($0.1.isMatch ? 0 : 1, $0.1.distance, $0.0) < ($1.1.isMatch ? 0 : 1, $1.1.distance, $1.0) }
            .map(\.1)
    }

    static func channelDistance(_ lhs: UInt32, _ rhs: UInt32) -> Int {
        [16, 8, 0].map { shift in
            abs(Int((lhs >> shift) & 0xFF) - Int((rhs >> shift) & 0xFF))
        }.max() ?? 0
    }

    /// Whether the reading's numbers equal the typed ones, and whether each is within one step
    /// of the precision typed (a typed `44` allows ±1; `0.2` allows ±0.1). On a 0–1 scale a
    /// whole number is exact, so a typed `1` allows one 8-bit step, not the whole range.
    static func compareNumbers(_ expected: ExpectedColor, _ reading: [String]) -> (exact: Bool, close: Bool) {
        if expected.format == .hex {
            let same = reading.first?.lowercased() == expected.values.first?.lowercased()
            return (same, same)
        }
        guard reading.count == expected.values.count else { return (false, false) }
        // Hue wraps: 359 and 1 are 2 apart.
        let hueIndex: Int? = switch expected.format {
        case .hsl, .hsb: 0
        case .oklch: 2
        default: nil
        }
        let hueTurn: Double = expected.style == .swiftUI ? 1 : 360
        let fractions: Set<Int> = switch (expected.format, expected.style) {
        case (.rgb, .swiftUI), (.hsb, .swiftUI), (.opengl, _): [0, 1, 2]
        case (.oklch, _): [1]
        default: []
        }
        var exact = true
        var close = true
        for (index, (typed, read)) in zip(expected.values, reading).enumerated() {
            guard let lhs = Double(typed), let rhs = Double(read) else { return (false, false) }
            var difference = abs(lhs - rhs)
            if index == hueIndex { difference = min(difference, hueTurn - difference) }
            if difference > 1e-9 { exact = false }
            // A 0–1 reading drops trailing zeros, so its text says nothing about its precision.
            let allowed = fractions.contains(index)
                ? max(typed.contains(".") ? step(typed) : 0, 1.0 / 255)
                : max(step(typed), step(read))
            if difference > allowed + 1e-9 { close = false }
        }
        return (exact, close)
    }

    /// One unit in the last decimal place written: `44` → 1, `0.186` → 0.001.
    private static func step(_ number: String) -> Double {
        guard let dot = number.firstIndex(of: ".") else { return 1 }
        return pow(10, -Double(number.distance(from: dot, to: number.endIndex) - 1))
    }
}
