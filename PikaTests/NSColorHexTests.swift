import XCTest
@testable import Pika

final class NSColorHexTests: XCTestCase {
    // MARK: - roundToHex()

    func test_roundToHex_zero_returnsZero() {
        XCTAssertEqual(NSColor.white.roundToHex(0.0), 0)
    }

    func test_roundToHex_negativeValue_returnsZero() {
        XCTAssertEqual(NSColor.white.roundToHex(-0.5), 0)
    }

    func test_roundToHex_one_returns255() {
        XCTAssertEqual(NSColor.white.roundToHex(1.0), 255)
    }

    func test_roundToHex_half_returns128() {
        // 0.5 * 255 = 127.5 → rounds to 128
        XCTAssertEqual(NSColor.white.roundToHex(0.5), 128)
    }

    func test_roundToHex_roundsCorrectly() {
        // 100/255 ≈ 0.392156... → round(0.392156 * 255) = round(100.0) = 100
        XCTAssertEqual(NSColor.white.roundToHex(100.0 / 255.0), 100)
    }

    // MARK: - toHex()

    func test_toHex_red() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toHex(), 0xFF0000)
    }

    func test_toHex_green() {
        let green = NSColor(red: 0, green: 1, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(green.toHex(), 0x00FF00)
    }

    func test_toHex_blue() {
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(blue.toHex(), 0x0000FF)
    }

    func test_toHex_black() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(black.toHex(), 0x000000)
    }

    func test_toHex_white() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(white.toHex(), 0xFFFFFF)
    }

    // MARK: - toHexString(style:)

    func test_toHexString_cssStyle_includesHash() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toHexString(style: .css), "#ff0000")
    }

    func test_toHexString_unformattedStyle_noHash() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toHexString(style: .unformatted), "ff0000")
    }

    func test_toHexString_defaultStyle_isCss() {
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(blue.toHexString(), "#0000ff")
    }

    func test_toHexString_white() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(white.toHexString(style: .css), "#ffffff")
    }

    func test_toHexString_black() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(black.toHexString(style: .css), "#000000")
    }

    func test_toHexString_isLowercase() {
        let color = NSColor(hex: "AABBCC")
        XCTAssertEqual(color.toHexString(style: .css), "#aabbcc")
    }

    func test_initHex_roundtrips_throughToHexString() {
        let original = "#3a7bd5"
        let color = NSColor(hex: original)
        XCTAssertEqual(color.toHexString(style: .css), original)
    }
}
