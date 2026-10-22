@testable import Pika
import XCTest

/// Check a Color's expected values: reading a value in any of Pika's formats, and matching a
/// pick against it in each colour space.
final class ExpectedColorTests: XCTestCase {
    /// One value to parse, and what it should parse as.
    private struct Case {
        let text: String
        let format: ColorFormat
        let style: CopyFormat
        let values: [String]

        init(_ text: String, _ format: ColorFormat, _ style: CopyFormat, _ values: [String]) {
            (self.text, self.format, self.style, self.values) = (text, format, style, values)
        }
    }

    func test_parse_detectsTheFormatFromTheValue() throws {
        let cases = [
            Case("#3A7BD5", .hex, .css, ["3a7bd5"]),
            Case("3a7bd5", .hex, .css, ["3a7bd5"]),
            Case("#fff", .hex, .css, ["ffffff"]),
            Case("rgb(58, 123, 213)", .rgb, .css, ["58", "123", "213"]),
            Case("hsl(215, 64%, 53%)", .hsl, .css, ["215", "64", "53"]),
            Case("hsb(215, 73%, 84%)", .hsb, .css, ["215", "73", "84"]),
            Case("oklch(55.6% 0.15 258)", .oklch, .css, ["55.6", "0.15", "258"]),
            Case("lab(51.2 6.9 -55.4)", .lab, .css, ["51.2", "6.9", "-55.4"]),
            Case("rgba(0.23, 0.48, 0.84, 1.0)", .opengl, .css, ["0.23", "0.48", "0.84"]),
            Case("Color(red: 0.2, green: 0.4, blue: 0.6)", .rgb, .swiftUI, ["0.2", "0.4", "0.6"]),
        ]
        for item in cases {
            let parsed = try XCTUnwrap(ExpectedColor.parse(item.text, fallback: .hex), item.text)
            XCTAssertEqual(parsed.format, item.format, item.text)
            XCTAssertEqual(parsed.style, item.style, item.text)
            XCTAssertEqual(parsed.values, item.values, item.text)
        }
    }

    func test_parse_readsBareNumbersInTheFallbackFormat() throws {
        XCTAssertEqual(ExpectedColor.parse("58, 123, 213", fallback: .rgb)?.format, .rgb)
        XCTAssertEqual(ExpectedColor.parse("215 64 53", fallback: .hsl)?.format, .hsl)
        XCTAssertNil(ExpectedColor.parse("nonsense", fallback: .rgb))
        XCTAssertNil(ExpectedColor.parse("58, 123", fallback: .rgb))
        XCTAssertNil(ExpectedColor.parse("", fallback: .hex))
    }

    func test_compare_rgbFindsTheSpace() throws {
        let picked = try XCTUnwrap(NSColor.fromHex("#3a7bd5", in: .sRGB))
        let expected = try XCTUnwrap(ExpectedColor.parse("rgb(58, 123, 213)", fallback: .hex))
        let best = try XCTUnwrap(ColorSpaceMatcher.compare(picked, expected: expected, in: [.displayP3, .sRGB]).first)
        XCTAssertEqual(best.space, .sRGB)
        XCTAssertTrue(best.isExact)
        XCTAssertEqual(best.reading, "rgb(58, 123, 213)")
    }

    func test_compare_hslWithinItsOwnRounding() throws {
        // #3a7bd5 is hsl(215.4°, 64.6%, 53.1%): typed as whole numbers, a step off at most.
        let picked = try XCTUnwrap(NSColor.fromHex("#3a7bd5", in: .sRGB))
        let expected = try XCTUnwrap(ExpectedColor.parse("hsl(215, 65%, 53%)", fallback: .hex))
        let matches = ColorSpaceMatcher.compare(picked, expected: expected, in: [.sRGB, .displayP3])
        XCTAssertEqual(matches.first?.space, .sRGB)
        XCTAssertEqual(matches.first?.isMatch, true)
        XCTAssertEqual(matches.last?.isMatch, false)
    }

    func test_compare_oklchIsOneReadingForEverySpace() throws {
        let picked = try XCTUnwrap(NSColor.fromHex("#3a7bd5", in: .sRGB))
        let reading = ColorFormat.oklch.decompose(picked, style: .css, in: .sRGB).joined()
        let expected = try XCTUnwrap(ExpectedColor.parse(reading, fallback: .hex))
        XCTAssertTrue(expected.isAbsolute)
        let matches = ColorSpaceMatcher.compare(picked, expected: expected)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.reading, reading)
        XCTAssertEqual(matches.first?.isExact, true)
    }

    func test_compareNumbers_hueWrapsAround() throws {
        let expected = ExpectedColor(format: .hsl, style: .css, values: ["359", "50", "50"])
        XCTAssertTrue(ColorSpaceMatcher.compareNumbers(expected, ["0", "50", "50"]).close)
        XCTAssertFalse(ColorSpaceMatcher.compareNumbers(expected, ["3", "50", "50"]).close)
    }

    func test_compareNumbers_wholeNumbersOnAZeroToOneScaleAreExact() throws {
        let red = try XCTUnwrap(ExpectedColor.parse("Color(red: 1, green: 0, blue: 0)", fallback: .hex))
        XCTAssertFalse(ColorSpaceMatcher.compareNumbers(red, ["0.2", "0.4", "0.6"]).close)
        XCTAssertTrue(ColorSpaceMatcher.compareNumbers(red, ["0.998", "0", "0.002"]).close)
        // A reading of exactly 0 doesn't widen the tolerance of a typed 0.4.
        let typed = ExpectedColor(format: .rgb, style: .swiftUI, values: ["0.2", "0.4", "0.6"])
        XCTAssertFalse(ColorSpaceMatcher.compareNumbers(typed, ["0.2", "0", "0.6"]).close)
        let gl = try XCTUnwrap(ExpectedColor.parse("rgba(1, 0, 0, 1)", fallback: .hex))
        XCTAssertFalse(ColorSpaceMatcher.compareNumbers(gl, ["0.5", "0.5", "0.5"]).close)
        let oklch = ExpectedColor(format: .oklch, style: .css, values: ["60", "0", "30"])
        XCTAssertFalse(ColorSpaceMatcher.compareNumbers(oklch, ["60", "0.2", "30"]).close)
    }
}
