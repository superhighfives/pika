import XCTest
@testable import Pika

final class NSColorLuminanceTests: XCTestCase {
    // MARK: - clip()

    func test_clip_belowMinimum_returnsMinimum() {
        let color = NSColor.white
        XCTAssertEqual(color.clip(-5, 0, 10), 0)
    }

    func test_clip_aboveMaximum_returnsMaximum() {
        let color = NSColor.white
        XCTAssertEqual(color.clip(15, 0, 10), 10)
    }

    func test_clip_withinRange_returnsValue() {
        let color = NSColor.white
        XCTAssertEqual(color.clip(5, 0, 10), 5)
    }

    func test_clip_atMinimum_returnsMinimum() {
        let color = NSColor.white
        XCTAssertEqual(color.clip(0, 0, 10), 0)
    }

    func test_clip_atMaximum_returnsMaximum() {
        let color = NSColor.white
        XCTAssertEqual(color.clip(10, 0, 10), 10)
    }

    // MARK: - luminance

    func test_luminance_white_isOne() {
        let white = NSColor(r: 1, g: 1, b: 1)
        XCTAssertEqual(white.luminance, 1.0, accuracy: 0.001)
    }

    func test_luminance_black_isZero() {
        let black = NSColor(r: 0, g: 0, b: 0)
        XCTAssertEqual(black.luminance, 0.0, accuracy: 0.001)
    }

    func test_luminance_midGray_isApproximatelyCorrect() {
        // sRGB 128,128,128 → relative luminance ≈ 0.216
        let gray = NSColor(r: 128, g: 128, b: 128)
        XCTAssertEqual(gray.luminance, 0.216, accuracy: 0.01)
    }

    func test_luminance_red_matchesWCAGFormula() {
        // Pure red sRGB luminance: 0.2126 * linearize(1.0) = 0.2126
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(red.luminance, 0.2126, accuracy: 0.01)
    }

    func test_luminance_green_matchesWCAGFormula() {
        // Pure green sRGB luminance: 0.7152 * linearize(1.0) = 0.7152
        let green = NSColor(red: 0, green: 1, blue: 0, alpha: 1)
        XCTAssertEqual(green.luminance, 0.7152, accuracy: 0.01)
    }

    func test_luminance_blue_matchesWCAGFormula() {
        // Pure blue sRGB luminance: 0.0722 * linearize(1.0) = 0.0722
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1)
        XCTAssertEqual(blue.luminance, 0.0722, accuracy: 0.01)
    }

    func test_luminance_isNonNegative() {
        // luminance should never go negative even for edge-case values
        let black = NSColor(r: 0, g: 0, b: 0)
        XCTAssertGreaterThanOrEqual(black.luminance, 0.0)
    }

    // MARK: - contrastRatio(with:)

    func test_contrastRatio_whiteOnBlack_is21() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let black = NSColor(r: 0, g: 0, b: 0)
        XCTAssertEqual(white.contrastRatio(with: black), 21.0, accuracy: 0.1)
    }

    func test_contrastRatio_isSymmetric() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let black = NSColor(r: 0, g: 0, b: 0)
        XCTAssertEqual(white.contrastRatio(with: black), black.contrastRatio(with: white), accuracy: 0.001)
    }

    func test_contrastRatio_sameColor_isOne() {
        let red = NSColor(r: 255, g: 0, b: 0)
        XCTAssertEqual(red.contrastRatio(with: red), 1.0, accuracy: 0.001)
    }

    func test_contrastRatio_isAtLeastOne() {
        let colorA = NSColor(r: 100, g: 150, b: 200)
        let colorB = NSColor(r: 50, g: 80, b: 120)
        XCTAssertGreaterThanOrEqual(colorA.contrastRatio(with: colorB), 1.0)
    }

    // MARK: - toContrastRatioString(with:)

    func test_toContrastRatioString_whiteOnBlack_returns21() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let black = NSColor(r: 0, g: 0, b: 0)
        let result = white.toContrastRatioString(with: black)
        XCTAssertTrue(result.hasPrefix("21"), "Expected '21...', got '\(result)'")
    }

    func test_toContrastRatioString_returnsNumericString() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let gray = NSColor(r: 128, g: 128, b: 128)
        let result = white.toContrastRatioString(with: gray)
        XCTAssertNotNil(Double(result), "Expected numeric string, got '\(result)'")
    }
}
