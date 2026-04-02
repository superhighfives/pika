import Defaults
@testable import Pika
import XCTest

final class NSColorHexTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Defaults[.colorSpace] = .sRGB
    }

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
        let color = NSColor(hex: "AABBCC").usingColorSpace(.sRGB)!
        XCTAssertEqual(color.toHexString(style: .css), "#aabbcc")
    }

    func test_initHex_roundtrips_throughToHexString() {
        let original = "#3a7bd5"
        let color = NSColor(hex: original).usingColorSpace(.sRGB)!
        XCTAssertEqual(color.toHexString(style: .css), original)
    }

    // MARK: - sRGB normalization stability

    func test_displayP3Color_normalizedToSRGB_roundTripsExactly() {
        // A Display P3 color normalized to sRGB should produce the same hex
        // when read back in sRGB, proving the storage path introduces no drift.
        let p3Color = NSColor(colorSpace: .displayP3, components: [0.055, 0.094, 0.161, 1.0], count: 4)
        let srgbColor = p3Color.usingColorSpace(.sRGB)!

        // Read hex in sRGB (the storage color space)
        let hex = srgbColor.toRGBAComponents(in: .sRGB)
        let reconstructed = NSColor(srgbRed: hex.r, green: hex.g, blue: hex.b, alpha: hex.a)
        let originalHex = srgbColor.toHex()
        let roundTrippedHex = reconstructed.toHex()

        // swiftlint:disable:next line_length
        XCTAssertEqual(originalHex, roundTrippedHex, "P3 color normalized to sRGB should round-trip without channel drift")
    }

    func test_sRGB_roundTrip_noChannelDrift() {
        // Verify that converting to sRGB and back to hex doesn't introduce
        // the 1-3 channel drift reported in issue #187.
        let original = "#0e1829"
        let color = NSColor(hex: original).usingColorSpace(.sRGB)!
        XCTAssertEqual(color.toHexString(style: .css), original)
    }
}
