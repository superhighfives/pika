import SwiftUI
import XCTest
@testable import Pika

final class NSColorRGBTests: XCTestCase {
    // MARK: - toRGBAComponents(in:)

    func test_toRGBAComponents_red() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        let rgba = red.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgba.g, 0.0, accuracy: 0.001)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.001)
        XCTAssertEqual(rgba.a, 1.0, accuracy: 0.001)
    }

    func test_toRGBAComponents_returnsAllFourChannels() {
        let color = NSColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 0.2, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 0.4, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.6, accuracy: 0.01)
        XCTAssertEqual(rgba.a, 0.8, accuracy: 0.01)
    }

    // MARK: - toRGBString(style:)

    func test_toRGBString_cssStyle_red() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toRGBString(style: .css), "rgb(255, 0, 0)")
    }

    func test_toRGBString_designStyle_noParenFormat() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toRGBString(style: .design), "rgb(255, 0, 0)")
    }

    func test_toRGBString_swiftUIStyle() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertTrue(red.toRGBString(style: .swiftUI).hasPrefix("Color(red:"))
    }

    func test_toRGBString_unformattedStyle() {
        let color = NSColor(red: 0, green: 128.0 / 255.0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let result = color.toRGBString(style: .unformatted)
        XCTAssertFalse(result.contains("rgb("))
        XCTAssertTrue(result.contains(","))
    }

    func test_toRGBString_defaultStyle_isCss() {
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(blue.toRGBString(), "rgb(0, 0, 255)")
    }

    func test_toRGBString_black() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(black.toRGBString(style: .css), "rgb(0, 0, 0)")
    }

    func test_toRGBString_white() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(white.toRGBString(style: .css), "rgb(255, 255, 255)")
    }

    // MARK: - toRGB8BitArray()

    func test_toRGB8BitArray_red() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toRGB8BitArray(), [255, 0, 0])
    }

    func test_toRGB8BitArray_returnsThreeElements() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toRGB8BitArray()
        XCTAssertEqual(result.count, 3)
    }

    func test_toRGB8BitArray_valuesInRange() {
        let color = NSColor(r: 64, g: 128, b: 192)
        let result = color.toRGB8BitArray()
        XCTAssertTrue(result.allSatisfy { $0 >= 0 && $0 <= 255 })
    }

    // MARK: - toFormat(format:style:)

    func test_toFormat_hex_delegatesToHexString() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toFormat(format: .hex, style: .css), "#ff0000")
    }

    func test_toFormat_rgb_delegatesToRGBString() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(red.toFormat(format: .rgb, style: .css), "rgb(255, 0, 0)")
    }

    func test_toFormat_returnsNonEmptyStringForAllFormats() {
        let color = NSColor(r: 100, g: 150, b: 200)
        for format in ColorFormat.allCases {
            let result = color.toFormat(format: format)
            XCTAssertFalse(result.isEmpty, "toFormat(\(format)) returned empty string")
        }
    }

    // MARK: - getUIColor()

    func test_getUIColor_darkColor_returnsSwiftUIWhite() {
        let black = NSColor(r: 0, g: 0, b: 0)
        let uiColor: SwiftUI.Color = black.getUIColor()
        XCTAssertEqual(uiColor, .white)
    }

    func test_getUIColor_lightColor_returnsSwiftUIBlack() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let uiColor: SwiftUI.Color = white.getUIColor()
        XCTAssertEqual(uiColor, .black)
    }

    func test_getUIColor_darkColor_returnsNSColorWhite() {
        let black = NSColor(r: 0, g: 0, b: 0)
        let nsColor: NSColor = black.getUIColor()
        XCTAssertEqual(nsColor, .white)
    }

    func test_getUIColor_lightColor_returnsNSColorBlack() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let nsColor: NSColor = white.getUIColor()
        XCTAssertEqual(nsColor, .black)
    }
}
