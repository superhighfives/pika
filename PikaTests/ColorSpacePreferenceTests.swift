import Defaults
@testable import Pika
import XCTest

/// The colour space setting, the "Colors don't match?" matcher, P3 CSS copy and the custom
/// picker's half-float capture.
final class ColorSpacePreferenceTests: XCTestCase {
    private static let keys = ["colorSpace", "colorSpaceMatchesDisplay"]
    private var saved: [Any?] = []

    override func setUp() {
        super.setUp()
        saved = Self.keys.map { UserDefaults.standard.object(forKey: $0) }
        Defaults[.colorSpaceMatchesDisplay] = false
        Defaults[.colorSpace] = .sRGB
    }

    override func tearDown() {
        // Exactly as before, including absent: the test host shares prefs with any installed Pika.
        for (key, value) in zip(Self.keys, saved) {
            if let value { UserDefaults.standard.set(value, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        super.tearDown()
    }

    // MARK: - Default and selection

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

    func test_reexpressStoredColors_keepsTheSameColours() throws {
        // `reexpressStoredColors` rewrites all four keys; put each back exactly as it was,
        // including absent, since the test host shares prefs with any installed Pika.
        let keys = ["palettes", "colorHistory", "undoStack", "redoStack"]
        let saved = keys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        let pair = ColorPair(id: UUID(), foregroundHex: "#ff8800", backgroundHex: "0a31bc", date: Date())
        Defaults[.palettes] = [Palette(id: UUID(), name: nil, pairs: [pair], createdAt: Date())]
        Defaults[.undoStack] = [[pair]]

        ColorSpacePreference.reexpressStoredColors(from: .adobeRGB1998, to: .sRGB)

        let converted = try XCTUnwrap(Defaults[.palettes].first?.pairs.first)
        XCTAssertEqual(converted.id, pair.id)
        XCTAssertTrue(converted.foregroundHex.hasPrefix("#"))
        XCTAssertFalse(converted.backgroundHex.hasPrefix("#"))
        XCTAssertEqual(Defaults[.undoStack].first?.first, converted)
        for (old, new) in [(pair.foregroundHex, converted.foregroundHex), (pair.backgroundHex, converted.backgroundHex)] {
            let original = try XCTUnwrap(NSColor.fromHex(old, in: .adobeRGB1998))
            let moved = try XCTUnwrap(NSColor.fromHex(new, in: .sRGB))
            // Within one 8-bit step: the same colour, re-rounded in sRGB (clipped where Adobe RGB
            // reaches outside it, which this pair stays clear of).
            XCTAssertLessThanOrEqual(
                ColorSpaceMatcher.channelDistance(moved.toHex(in: .sRGB), original.toHex(in: .sRGB)), 1
            )
        }
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
