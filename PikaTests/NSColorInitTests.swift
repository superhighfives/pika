@testable import Pika
import XCTest

final class NSColorInitTests: XCTestCase {
    // MARK: - init(r:g:b:a:) — 255-based values

    func test_initRGB_255Based_normalizesComponents() {
        let color = NSColor(r: 255, g: 128, b: 0)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 128.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.01)
        XCTAssertEqual(rgba.a, 1.0, accuracy: 0.01)
    }

    func test_initRGB_255Based_withAlpha() {
        let color = NSColor(r: 0, g: 0, b: 255, a: 0.5)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.b, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.a, 0.5, accuracy: 0.01)
    }

    // MARK: - init(r:g:b:a:) — 0–1 based values

    func test_initRGB_normalizedValues_usedDirectly() {
        let color = NSColor(r: 0.5, g: 0.25, b: 0.75)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 0.5, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 0.25, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.75, accuracy: 0.01)
    }

    func test_initRGB_black() {
        let color = NSColor(r: 0, g: 0, b: 0)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 0.0, accuracy: 0.001)
        XCTAssertEqual(rgba.g, 0.0, accuracy: 0.001)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.001)
    }

    // MARK: - init(hex:alpha:)

    func test_initHex_6Char_parsesCorrectly() {
        let red = NSColor(hex: "FF0000")
        let rgba = red.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.01)
    }

    func test_initHex_withHashPrefix_stripped() {
        let color = NSColor(hex: "#00FF00")
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.01)
    }

    func test_initHex_3Char_expandedCorrectly() {
        // "F00" should expand to "FF0000"
        let color = NSColor(hex: "F00")
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.0, accuracy: 0.01)
    }

    func test_initHex_withAlpha() {
        let color = NSColor(hex: "0000FF", alpha: 0.5)
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.b, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgba.a, 0.5, accuracy: 0.01)
    }

    func test_initHex_black() {
        let color = NSColor(hex: "000000")
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r + rgba.g + rgba.b, 0.0, accuracy: 0.001)
    }

    func test_initHex_white() {
        let color = NSColor(hex: "FFFFFF")
        let rgba = color.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgba.g, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgba.b, 1.0, accuracy: 0.001)
    }

    func test_initHex_mixedCase() {
        let lower = NSColor(hex: "ff8800")
        let upper = NSColor(hex: "FF8800")
        let lRGBA = lower.toRGBAComponents(in: .sRGB)
        let uRGBA = upper.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(lRGBA.r, uRGBA.r, accuracy: 0.001)
        XCTAssertEqual(lRGBA.g, uRGBA.g, accuracy: 0.001)
        XCTAssertEqual(lRGBA.b, uRGBA.b, accuracy: 0.001)
    }
}
