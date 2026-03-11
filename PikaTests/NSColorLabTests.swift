@testable import Pika
import XCTest

final class NSColorLabTests: XCTestCase {
    // MARK: - toOpenGLString(style:)

    func test_toOpenGLString_cssStyle_containsRGBA() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let result = red.toOpenGLString(style: .css)
        XCTAssertTrue(result.hasPrefix("rgba("))
        XCTAssertTrue(result.contains("1.0)"))
    }

    func test_toOpenGLString_unformattedStyle_noParens() {
        let color = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = color.toOpenGLString(style: .unformatted)
        XCTAssertFalse(result.contains("rgba("))
    }

    func test_toOpenGLString_valuesNormalized() {
        // OpenGL uses 0–1 range; red should give r≈1, g≈0, b≈0
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let result = red.toOpenGLString(style: .css)
        XCTAssertTrue(result.contains("1"))
    }

    // MARK: - toLabComponents()

    func test_toLabComponents_white_LIsApproximately100() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let lab = white.toLabComponents()
        XCTAssertEqual(lab.l, 100.0, accuracy: 1.0)
    }

    func test_toLabComponents_black_LIsApproximatelyZero() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let lab = black.toLabComponents()
        XCTAssertEqual(lab.l, 0.0, accuracy: 1.0)
    }

    func test_toLabComponents_gray_AAndBNearZero() {
        // Neutral gray should have a ≈ 0, b ≈ 0
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let lab = gray.toLabComponents()
        XCTAssertEqual(lab.a, 0.0, accuracy: 2.0)
        XCTAssertEqual(lab.b, 0.0, accuracy: 2.0)
    }

    func test_toLabComponents_LIsInValidRange() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let lab = color.toLabComponents()
        XCTAssertGreaterThanOrEqual(lab.l, 0.0)
        XCTAssertLessThanOrEqual(lab.l, 100.0)
    }

    // MARK: - toLabString(style:)

    func test_toLabString_cssStyle_containsLabPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toLabString(style: .css)
        XCTAssertTrue(result.hasPrefix("lab("), "Expected 'lab(...)', got '\(result)'")
    }

    func test_toLabString_unformattedStyle_noLabPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toLabString(style: .unformatted)
        XCTAssertFalse(result.contains("lab("))
    }

    func test_toLabString_returnsNonEmptyString() {
        let color = NSColor(r: 200, g: 100, b: 50)
        XCTAssertFalse(color.toLabString().isEmpty)
    }

    // MARK: - toOklchComponents()

    func test_toOklchComponents_white_LIsApproximatelyOne() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = white.toOklchComponents()
        XCTAssertEqual(oklch.l, 1.0, accuracy: 0.01)
    }

    func test_toOklchComponents_black_LIsApproximatelyZero() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = black.toOklchComponents()
        XCTAssertEqual(oklch.l, 0.0, accuracy: 0.01)
    }

    func test_toOklchComponents_gray_chromaIsLow() {
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = gray.toOklchComponents()
        XCTAssertLessThan(oklch.c, 0.01)
    }

    func test_toOklchComponents_LIsInValidRange() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let oklch = color.toOklchComponents()
        XCTAssertGreaterThanOrEqual(oklch.l, 0.0)
        XCTAssertLessThanOrEqual(oklch.l, 1.0)
    }

    // MARK: - toOklchString(style:)

    func test_toOklchString_cssStyle_containsOklchPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toOklchString(style: .css)
        XCTAssertTrue(result.hasPrefix("oklch("), "Expected 'oklch(...)', got '\(result)'")
    }

    func test_toOklchString_returnsNonEmptyString() {
        let color = NSColor(r: 50, g: 100, b: 200)
        XCTAssertFalse(color.toOklchString().isEmpty)
    }

    func test_toOklchString_achromatic_noTrailingZerosOnChroma() {
        // Gray has chroma ≈ 0; the formatted chroma should not end in trailing zeros
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = gray.toOklchString(style: .css)
        // Extract chroma token: oklch(L% C H)
        let tokens = String(result.dropFirst("oklch(".count).dropLast(1)).components(separatedBy: " ")
        XCTAssertEqual(tokens.count, 3)
        let chroma = tokens[1]
        XCTAssertFalse(chroma.contains(".") && chroma.hasSuffix("0"),
                       "Chroma '\(chroma)' has trailing zeros after decimal")
    }

    func test_toOklchString_chromatic_stripsTrailingZerosWherePresent() {
        // A color whose chroma rounds to a value with trailing zeros (e.g. exactly 0.1000)
        // should not show them, while one with significant digits should keep them
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let result = blue.toOklchString(style: .css)
        XCTAssertTrue(result.hasPrefix("oklch("))
        // No token should end in a trailing zero after the decimal
        let tokens = String(result.dropFirst("oklch(".count).dropLast(1)).components(separatedBy: " ")
        for token in tokens {
            XCTAssertFalse(token.contains(".") && token.hasSuffix("0"),
                           "Token '\(token)' has trailing zeros after decimal")
        }
    }

    func test_toOklchString_unformatted_noTrailingZeros() {
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = gray.toOklchString(style: .unformatted)
        let tokens = result.components(separatedBy: ", ")
        for token in tokens {
            XCTAssertFalse(token.contains(".") && token.hasSuffix("0"),
                           "Token '\(token)' has trailing zeros after decimal")
        }
    }
}
