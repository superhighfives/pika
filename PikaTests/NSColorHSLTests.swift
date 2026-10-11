import Defaults
@testable import Pika
import XCTest

final class NSColorHSLTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Defaults[.colorSpace] = .sRGB
    }

    // MARK: - toHSBComponents()

    func test_toHSBComponents_red_hueIsZero() {
        let red = NSColor(hex: "FF0000")
        let hsb = red.toHSBComponents()
        XCTAssertEqual(hsb.h, 0.0, accuracy: 0.01)
        XCTAssertEqual(hsb.s, 1.0, accuracy: 0.01)
        XCTAssertEqual(hsb.b, 1.0, accuracy: 0.01)
    }

    func test_toHSBComponents_black_allZero() {
        let black = NSColor(hex: "000000")
        let hsb = black.toHSBComponents()
        XCTAssertEqual(hsb.h, 0.0, accuracy: 0.001)
        XCTAssertEqual(hsb.s, 0.0, accuracy: 0.001)
        XCTAssertEqual(hsb.b, 0.0, accuracy: 0.001)
    }

    func test_toHSBComponents_white_brightnessIsOne() {
        let white = NSColor(hex: "FFFFFF")
        let hsb = white.toHSBComponents()
        XCTAssertEqual(hsb.b, 1.0, accuracy: 0.001)
    }

    // MARK: - toHSBString(style:)

    func test_toHSBString_cssStyle_red() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSBString(style: .css)
        XCTAssertEqual(result, "hsb(0, 100%, 100%)")
    }

    func test_toHSBString_designStyle_noPercentSigns() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSBString(style: .design)
        XCTAssertFalse(result.contains("%"))
    }

    func test_toHSBString_swiftUIStyle_containsColorHue() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSBString(style: .swiftUI)
        XCTAssertTrue(result.contains("Color(hue:"))
    }

    func test_toHSBString_unformattedStyle_noParens() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSBString(style: .unformatted)
        XCTAssertFalse(result.contains("hsb("))
        XCTAssertFalse(result.contains("("))
    }

    // MARK: - toHSLComponents()

    func test_toHSLComponents_red_correctValues() {
        let red = NSColor(hex: "FF0000")
        let hsl = red.toHSLComponents()
        XCTAssertEqual(hsl.h, 0.0, accuracy: 0.01) // hue = 0°
        XCTAssertEqual(hsl.s, 1.0, accuracy: 0.01) // saturation = 100%
        XCTAssertEqual(hsl.l, 0.5, accuracy: 0.01) // lightness = 50%
    }

    func test_toHSLComponents_black_allZero() {
        let black = NSColor(hex: "000000")
        let hsl = black.toHSLComponents()
        XCTAssertEqual(hsl.h, 0.0, accuracy: 0.001)
        XCTAssertEqual(hsl.s, 0.0, accuracy: 0.001)
        XCTAssertEqual(hsl.l, 0.0, accuracy: 0.001)
    }

    func test_toHSLComponents_white_lightnessIsOne() {
        let white = NSColor(hex: "FFFFFF")
        let hsl = white.toHSLComponents()
        XCTAssertEqual(hsl.l, 1.0, accuracy: 0.001)
    }

    func test_toHSLComponents_midGray_saturationIsZero() {
        let gray = NSColor(hex: "808080")
        let hsl = gray.toHSLComponents()
        XCTAssertEqual(hsl.s, 0.0, accuracy: 0.01)
        XCTAssertEqual(hsl.l, 0.5, accuracy: 0.02)
    }

    // MARK: - toHSLString(style:)

    func test_toHSLString_cssStyle_red() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSLString(style: .css)
        XCTAssertEqual(result, "hsl(0, 100%, 50%)")
    }

    func test_toHSLString_designStyle_noPercentSigns() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSLString(style: .design)
        XCTAssertFalse(result.contains("%"))
        XCTAssertTrue(result.hasPrefix("hsl("))
    }

    func test_toHSLString_unformattedStyle_numbersOnly() {
        let red = NSColor(hex: "FF0000")
        let result = red.toHSLString(style: .unformatted)
        XCTAssertFalse(result.contains("hsl"))
        XCTAssertFalse(result.contains("%"))
    }

    func test_toHSLString_returnsNonEmptyString() {
        let color = NSColor(hex: "3A7BD5")
        XCTAssertFalse(color.toHSLString().isEmpty)
    }

    // MARK: - fromHSB / fromHSL — inverse round-trips (colorSpace pinned to sRGB in setUp)

    private let roundTripSamples = ["3A7BD5", "E32C88", "00FF00", "808080", "FF8800", "123456"]

    func test_fromHSB_roundTrip_matchesOriginalRGB() {
        for hex in roundTripSamples {
            let original = NSColor(hex: hex)
            let hsb = original.toHSBComponents()
            let rebuilt = NSColor.fromHSB(h: hsb.h, s: hsb.s, b: hsb.b)
            let o = original.toRGBAComponents(in: .sRGB)
            let r = rebuilt.toRGBAComponents(in: .sRGB)
            XCTAssertEqual(r.r, o.r, accuracy: 0.005, "R mismatch for \(hex)")
            XCTAssertEqual(r.g, o.g, accuracy: 0.005, "G mismatch for \(hex)")
            XCTAssertEqual(r.b, o.b, accuracy: 0.005, "B mismatch for \(hex)")
        }
    }

    func test_fromHSL_roundTrip_matchesOriginalRGB() {
        for hex in roundTripSamples {
            let original = NSColor(hex: hex)
            let hsl = original.toHSLComponents()
            let rebuilt = NSColor.fromHSL(h: hsl.h, s: hsl.s, l: hsl.l)
            let o = original.toRGBAComponents(in: .sRGB)
            let r = rebuilt.toRGBAComponents(in: .sRGB)
            XCTAssertEqual(r.r, o.r, accuracy: 0.005, "R mismatch for \(hex)")
            XCTAssertEqual(r.g, o.g, accuracy: 0.005, "G mismatch for \(hex)")
            XCTAssertEqual(r.b, o.b, accuracy: 0.005, "B mismatch for \(hex)")
        }
    }

    func test_fromHSB_zeroSaturation_isGray() {
        let rebuilt = NSColor.fromHSB(h: 0.5, s: 0, b: 0.6).toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rebuilt.r, 0.6, accuracy: 0.005)
        XCTAssertEqual(rebuilt.g, 0.6, accuracy: 0.005)
        XCTAssertEqual(rebuilt.b, 0.6, accuracy: 0.005)
    }

    func test_fromHSL_zeroSaturation_isGray() {
        let rebuilt = NSColor.fromHSL(h: 0.5, s: 0, l: 0.4).toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rebuilt.r, 0.4, accuracy: 0.005)
        XCTAssertEqual(rebuilt.g, 0.4, accuracy: 0.005)
        XCTAssertEqual(rebuilt.b, 0.4, accuracy: 0.005)
    }
}
