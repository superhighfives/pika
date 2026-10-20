import Defaults
@testable import Pika
import XCTest

/// The colour space setting, the "Colors don't match?" matcher, P3 CSS copy and the custom
/// picker's half-float capture.
final class ColorSpacePreferenceTests: XCTestCase {
    private static let keys = ["colorSpace", "colorSpaceMatchesDisplay"]
    private var saved: [Any?] = []

    /// What's actually written for `key`, not a registered default (see `isPersisted`).
    private static func persisted(_ key: String) -> Any? {
        UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?[key]
    }

    override func setUp() {
        super.setUp()
        saved = Self.keys.map { Self.persisted($0) }
        Defaults[.colorSpaceMatchesDisplay] = false
        Defaults[.colorSpace] = .sRGB
    }

    override func tearDown() {
        // Exactly as before, including absent: the test host shares prefs with any installed Pika.
        for (key, value) in zip(Self.keys, saved) {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    // MARK: - Default and selection

    func test_isPersisted_ignoresRegisteredDefaults() {
        UserDefaults.standard.removeObject(forKey: "colorSpace")
        // `Defaults` registers the default, so `object(forKey:)` still answers…
        XCTAssertEqual(Defaults[.colorSpace], .sRGB)
        // …but nothing was written.
        XCTAssertFalse(ColorSpacePreference.isPersisted("colorSpace"))
        Defaults[.colorSpace] = .displayP3
        XCTAssertTrue(ColorSpacePreference.isPersisted("colorSpace"))
    }

    func test_storedColorSpace_isNilWhenMissingOrUndecodable() {
        UserDefaults.standard.removeObject(forKey: "colorSpace")
        XCTAssertNil(ColorSpacePreference.storedColorSpace())
        UserDefaults.standard.set(Data([0x00, 0x01, 0x02]), forKey: "colorSpace")
        XCTAssertNil(ColorSpacePreference.storedColorSpace(), "corrupt data isn't a choice")
        XCTAssertEqual(Defaults[.colorSpace], .sRGB, "Defaults falls back to the default")
        Defaults[.colorSpace] = .adobeRGB1998
        XCTAssertEqual(ColorSpacePreference.storedColorSpace(), .adobeRGB1998)
    }

    func test_default_isSRGB() {
        XCTAssertEqual(Defaults.Keys.colorSpace.defaultValue, .sRGB)
    }

    func test_select_space_storesItAndStopsMatchingDisplay() {
        Defaults[.colorSpaceMatchesDisplay] = true
        ColorSpacePreference.select(.space(.displayP3))
        XCTAssertEqual(Defaults[.colorSpace], .displayP3)
        XCTAssertFalse(Defaults[.colorSpaceMatchesDisplay])
        XCTAssertEqual(ColorSpacePreference.current, .space(.displayP3))
    }

    func test_select_matchDisplay_adoptsTheScreensProfile() throws {
        let screenSpace = try XCTUnwrap(NSScreen.main?.colorSpace)
        ColorSpacePreference.select(.matchDisplay)
        XCTAssertTrue(Defaults[.colorSpaceMatchesDisplay])
        XCTAssertEqual(Defaults[.colorSpace], screenSpace)
        XCTAssertEqual(ColorSpacePreference.current, .matchDisplay)
    }

    func test_followDisplay_doesNothingForAFixedSpace() {
        ColorSpacePreference.select(.space(.adobeRGB1998))
        ColorSpacePreference.followDisplay(NSScreen.main)
        XCTAssertEqual(Defaults[.colorSpace], .adobeRGB1998)
    }

    func test_isCommon() {
        XCTAssertTrue(ColorSpacePreference.isCommon(.sRGB))
        XCTAssertTrue(ColorSpacePreference.isCommon(.displayP3))
        XCTAssertFalse(ColorSpacePreference.isCommon(.adobeRGB1998))
        XCTAssertFalse(ColorSpacePreference.isCommon(.genericRGB))
    }

    func test_readsColorSpace_onlyForRGBBasedFormats() {
        XCTAssertEqual(
            ColorFormat.allCases.filter(\.readsColorSpace),
            [.hex, .rgb, .hsb, .hsl, .opengl]
        )
    }

    // MARK: - Stored colours

    /// Puts back exactly what was stored under `keys` (including absent) after `body`: the test
    /// host shares prefs with any installed Pika.
    private func preservingDefaults(_ keys: [String], _ body: () throws -> Void) rethrows {
        let saved = keys.map { Self.persisted($0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
        try body()
    }

    func test_pinStoredColors_keepsTheColoursTheyWereWrittenIn() throws {
        try preservingDefaults(["palettes", "colorHistory", "undoStack", "redoStack"]) {
            UserDefaults.standard.removeObject(forKey: "colorHistory")
            UserDefaults.standard.removeObject(forKey: "redoStack")
            let legacy = ColorPair(id: UUID(), foregroundHex: "#ff8800", backgroundHex: "0a31bc", date: Date())
            Defaults[.palettes] = [Palette(id: UUID(), name: nil, pairs: [legacy], createdAt: Date())]
            Defaults[.undoStack] = [[legacy]]

            ColorSpacePreference.pinStoredColors(readingHexIn: .adobeRGB1998)

            let pinned = try XCTUnwrap(Defaults[.palettes].first?.pairs.first)
            XCTAssertEqual(pinned.id, legacy.id)
            XCTAssertEqual(pinned.foregroundHex, legacy.foregroundHex, "hex is kept as the record")
            XCTAssertNotNil(pinned.foregroundComponents)
            XCTAssertNotNil(Defaults[.undoStack].first?.first?.backgroundComponents)
            // The colours are the ones the hex described in Adobe RGB, whatever space is set now.
            for space in [NSColorSpace.sRGB, .displayP3] {
                Defaults[.colorSpace] = space
                XCTAssertEqual(pinned.foregroundColor.toHex(in: .adobeRGB1998), 0xFF8800)
                XCTAssertEqual(pinned.backgroundColor.toHex(in: .adobeRGB1998), 0x0A31BC)
            }
            // Keys that weren't stored stay absent.
            XCTAssertFalse(ColorSpacePreference.isPersisted("colorHistory"))
            XCTAssertFalse(ColorSpacePreference.isPersisted("redoStack"))
        }
    }

    func test_colorPair_keepsItsColourWhenTheSpaceChanges() throws {
        let orange = try XCTUnwrap(NSColor.fromHex("#ff8800", in: .displayP3))
        let pair = ColorPair(foreground: orange, background: .black)
        for space in [NSColorSpace.sRGB, .displayP3, .adobeRGB1998] {
            Defaults[.colorSpace] = space
            XCTAssertEqual(pair.foregroundColor.toHex(in: .displayP3), 0xFF8800)
        }
    }

    func test_colorPair_keepsAColourOutsideTheSpace() throws {
        // P3 red is outside sRGB; a hex in sRGB would clip it, the components don't.
        let red = NSColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
        let pair = ColorPair(foreground: red, background: .black)
        let restored = try XCTUnwrap(pair.foregroundColor.usingColorSpace(.displayP3))
        XCTAssertEqual(restored.redComponent, 1, accuracy: 1e-5)
        XCTAssertEqual(restored.greenComponent, 0, accuracy: 1e-5)
        XCTAssertEqual(restored.blueComponent, 0, accuracy: 1e-5)
    }

    func test_colorPair_decodesEntriesSavedBefore202() throws {
        let json = "{\"id\":\"8C2F8E5E-6B7B-4E61-9A1E-6E1B8E0F1A2B\",\"foregroundHex\":\"#112233\","
            + "\"backgroundHex\":\"#ffffff\",\"date\":0}"
        let pair = try JSONDecoder().decode(ColorPair.self, from: Data(json.utf8))
        XCTAssertNil(pair.foregroundComponents)
        XCTAssertEqual(pair.foregroundColor.toHexString(), "#112233")
        let roundTrip = try JSONDecoder().decode(ColorPair.self, from: JSONEncoder().encode(pair.pinned(readingHexIn: .sRGB)))
        XCTAssertNotNil(roundTrip.foregroundComponents)
        XCTAssertEqual(roundTrip.foregroundColor.toHexString(), "#112233")
    }

    func test_colorPair_swappedExchangesColoursAndKeepsTheEntry() throws {
        let orange = try XCTUnwrap(NSColor.fromHex("#ff8800", in: .sRGB))
        let pair = ColorPair(foreground: orange, background: .black)
        let swapped = pair.swapped
        XCTAssertEqual(swapped.id, pair.id)
        XCTAssertEqual(swapped.foregroundComponents, pair.backgroundComponents)
        XCTAssertEqual(swapped.backgroundColor.toHexString(), "#ff8800")
    }

    // MARK: - Matcher

    func test_channelDistance_isTheLargestChannelDifference() {
        XCTAssertEqual(ColorSpaceMatcher.channelDistance(0x0E1829, 0x0E1829), 0)
        XCTAssertEqual(ColorSpaceMatcher.channelDistance(0x0E1829, 0x111726), 3)
        XCTAssertEqual(ColorSpaceMatcher.channelDistance(0x000000, 0xFF0000), 255)
    }

    func test_compare_findsTheSpaceTheHexWasWrittenIn() throws {
        let spaces: [NSColorSpace] = [.sRGB, .displayP3, .adobeRGB1998]
        for space in spaces {
            let color = try XCTUnwrap(NSColor.fromHex("#3a7bd5", in: space)?.usingColorSpace(.extendedSRGB))
            let best = try XCTUnwrap(ColorSpaceMatcher.compare(color, expected: 0x3A7BD5, in: spaces).first)
            XCTAssertEqual(best.space, space)
            XCTAssertEqual(best.distance, 0)
            XCTAssertTrue(best.isMatch)
        }
    }

    func test_compare_reportsHowFarOffTheOthersAre() throws {
        let color = try XCTUnwrap(NSColor.fromHex("#ff0000", in: .sRGB))
        let matches = ColorSpaceMatcher.compare(color, expected: 0xFF0000, in: [.sRGB, .displayP3])
        XCTAssertEqual(matches.map(\.space), [.sRGB, .displayP3])
        XCTAssertGreaterThan(matches[1].distance, ColorSpaceMatcher.tolerance)
        XCTAssertFalse(matches[1].isMatch)
    }

    func test_compare_tieKeepsCandidateOrder() throws {
        // A neutral grey is the same in sRGB and Display P3, so sRGB (listed first) wins.
        let grey = try XCTUnwrap(NSColor.fromHex("#808080", in: .sRGB))
        let matches = ColorSpaceMatcher.compare(grey, expected: 0x808080, in: [.sRGB, .displayP3])
        XCTAssertEqual(matches.first?.space, .sRGB)
        XCTAssertEqual(matches.map(\.distance), [0, 0])
    }

    func test_candidates_startWithSRGBAndP3_withoutDuplicates() {
        let candidates = ColorSpaceMatcher.candidates()
        XCTAssertEqual(Array(candidates.prefix(2)), [.sRGB, .displayP3])
        XCTAssertEqual(candidates.count, Set(candidates).count)
        XCTAssertTrue(candidates.contains(.adobeRGB1998))
    }

    // MARK: - CSS copy in Display P3

    func test_copy_inDisplayP3_namesTheSpaceForCSSHexAndRGB() throws {
        let color = try XCTUnwrap(NSColor.fromHex("#ff8800", in: .displayP3))
        XCTAssertEqual(
            color.toCopyString(format: .hex, style: .css, in: .displayP3), "color(display-p3 1 0.5333 0)"
        )
        XCTAssertEqual(
            color.toCopyString(format: .rgb, style: .css, in: .displayP3), "color(display-p3 1 0.5333 0)"
        )
    }

    func test_copy_otherwiseMatchesTheReadout() throws {
        Defaults[.colorSpace] = .displayP3
        let color = try XCTUnwrap(NSColor.fromHex("#ff8800", in: .displayP3))
        for (format, style) in [(ColorFormat.hex, CopyFormat.design), (.hex, .unformatted), (.oklch, .css), (.hsl, .css)] {
            XCTAssertEqual(
                color.toCopyString(format: format, style: style, in: .displayP3),
                color.toFormat(format: format, style: style)
            )
        }
        Defaults[.colorSpace] = .sRGB
        let srgb = try XCTUnwrap(NSColor.fromHex("#ff8800", in: .sRGB))
        XCTAssertEqual(srgb.toCopyString(format: .hex, style: .css, in: .sRGB), "#ff8800")
    }

    // MARK: - Half-float capture

    func test_floatFromHalf() {
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x0000), 0)
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x3C00), 1)
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x3800), 0.5)
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x3D00), 1.25)
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0xC000), -2)
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x0001), pow(2, -24))
        XCTAssertEqual(PickerLoupeController.float(fromHalf: 0x7C00), .infinity)
    }

    /// A 4×4 half-float linear P3 image: every pixel (0.5, 0.5, 0.5), except (`odd`) one.
    private func halfFloatImage(odd: (x: Int, y: Int)) throws -> CGImage {
        var bytes: [UInt8] = []
        for y in 0 ..< 4 {
            for x in 0 ..< 4 {
                let red: UInt16 = (x, y) == odd ? 0x3C00 : 0x3800
                for half in [red, 0x3800, 0x3800, 0x3C00] {
                    bytes += [UInt8(half & 0xFF), UInt8(half >> 8)]
                }
            }
        }
        let space = try XCTUnwrap(CGColorSpace(name: PickerLoupeController.captureSpaceName))
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let info = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.floatComponents.rawValue
                | CGBitmapInfo.byteOrder16Little.rawValue
        )
        return try XCTUnwrap(CGImage(
            width: 4, height: 4, bitsPerComponent: 16, bitsPerPixel: 64, bytesPerRow: 32,
            space: space, bitmapInfo: info, provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
    }

    func test_isUniform_tellsAFlatPointFromAnEdge() throws {
        let image = try halfFloatImage(odd: (x: 3, y: 3))
        XCTAssertTrue(PickerLoupeController.isUniform(image, x: 0, y: 0, size: 2))
        XCTAssertTrue(PickerLoupeController.isUniform(image, x: 2, y: 0, size: 2))
        XCTAssertFalse(PickerLoupeController.isUniform(image, x: 2, y: 2, size: 2), "holds the odd pixel")
        XCTAssertFalse(PickerLoupeController.isUniform(image, x: 3, y: 3, size: 2), "runs off the edge")
    }

    func test_centerPixelColor_readsHalfFloatLinearP3() throws {
        // What the Pro picker captures (`captureSpaceName`): P3 red, linear, which sRGB can't hold.
        let halves: [UInt16] = [0x3C00, 0x0000, 0x0000, 0x3C00]
        let bytes = (0 ..< 9).flatMap { _ in halves.flatMap { [UInt8($0 & 0xFF), UInt8($0 >> 8)] } }
        let space = try XCTUnwrap(CGColorSpace(name: PickerLoupeController.captureSpaceName))
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let info = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.floatComponents.rawValue
                | CGBitmapInfo.byteOrder16Little.rawValue
        )
        let image = try XCTUnwrap(CGImage(
            width: 3, height: 3, bitsPerComponent: 16, bitsPerPixel: 64, bytesPerRow: 24,
            space: space, bitmapInfo: info, provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let color = try XCTUnwrap(PickerLoupeController.centerPixelColor(of: image))
        XCTAssertEqual(color.toHex(in: .displayP3), 0xFF0000)
        let extended = try XCTUnwrap(color.usingColorSpace(.extendedSRGB))
        XCTAssertGreaterThan(extended.redComponent, 1)
        XCTAssertLessThan(extended.greenComponent, 0)
    }

    func test_centerPixelColor_readsHalfFloatExtendedSRGB() throws {
        // 3×3 RGBA half-float, every pixel (1.25, 0.5, -0.125, 1): outside sRGB on two channels.
        let halves: [UInt16] = [0x3D00, 0x3800, 0xB000, 0x3C00]
        var bytes: [UInt8] = []
        for _ in 0 ..< 9 {
            for half in halves {
                bytes += [UInt8(half & 0xFF), UInt8(half >> 8)]
            }
        }
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let info = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.floatComponents.rawValue
                | CGBitmapInfo.byteOrder16Little.rawValue
        )
        let image = try XCTUnwrap(CGImage(
            width: 3, height: 3, bitsPerComponent: 16, bitsPerPixel: 64, bytesPerRow: 24,
            space: space, bitmapInfo: info, provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        ))
        let color = try XCTUnwrap(PickerLoupeController.centerPixelColor(of: image))
        let extended = try XCTUnwrap(color.usingColorSpace(.extendedSRGB))
        XCTAssertEqual(extended.redComponent, 1.25, accuracy: 1e-6)
        XCTAssertEqual(extended.greenComponent, 0.5, accuracy: 1e-6)
        XCTAssertEqual(extended.blueComponent, -0.125, accuracy: 1e-6)
    }
}
