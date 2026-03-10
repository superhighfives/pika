@testable import Pika
import XCTest

final class APCAComplianceTests: XCTestCase {
    // MARK: - APCACompliance(with:) — level strings

    func test_blackOnWhite_isHighLevel() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let result = black.APCACompliance(with: white)
        // Black text on white background should be "Super" (Lc > 60)
        XCTAssertEqual(result.level, "Super")
    }

    func test_whiteOnBlack_isHighLevel() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let result = white.APCACompliance(with: black)
        XCTAssertEqual(result.level, "Super")
    }

    func test_sameColor_levelIsFail() {
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = gray.APCACompliance(with: gray)
        XCTAssertEqual(result.level, "Fail")
    }

    func test_level_allCasesAreKnownStrings() {
        let knownLevels: Set<String> = ["Fail", "AA", "AAA", "AAA+", "Super"]
        let pairs: [(NSColor, NSColor)] = [
            (NSColor(r: 0, g: 0, b: 0), NSColor(r: 0, g: 0, b: 0)),
            (NSColor(r: 50, g: 50, b: 50), NSColor(r: 240, g: 240, b: 240)),
            (NSColor(r: 0, g: 0, b: 0), NSColor(r: 255, g: 255, b: 255)),
        ]
        for (fg, bg) in pairs {
            let level = fg.APCACompliance(with: bg).level
            XCTAssertTrue(knownLevels.contains(level), "Unexpected level: \(level)")
        }
    }

    // MARK: - toAPCAcontrastValue(with:)

    func test_toAPCAcontrastValue_blackOnWhite_isHighValue() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let value = black.toAPCAcontrastValue(with: white)
        let doubleValue = Double(value.replacingOccurrences(of: ",", with: "."))
        XCTAssertNotNil(doubleValue, "Expected numeric string, got '\(value)'")
        XCTAssertGreaterThan(doubleValue ?? 0, 60.0)
    }

    func test_toAPCAcontrastValue_formattedToTwoDecimalPlaces() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let value = black.toAPCAcontrastValue(with: white)
        // Should contain a decimal separator
        XCTAssertTrue(value.contains(".") || value.contains(","))
    }

    func test_toAPCAcontrastValue_isAlwaysPositive() {
        // The function uses abs(), so result should be non-negative
        let colorA = NSColor(r: 100, g: 100, b: 100)
        let colorB = NSColor(r: 200, g: 200, b: 200)
        let value = colorA.toAPCAcontrastValue(with: colorB)
        let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) ?? -1
        XCTAssertGreaterThanOrEqual(doubleValue, 0)
    }

    // MARK: - toAPCACompliance(with:) alias

    func test_toAPCACompliance_equivalentToAPCACompliance() {
        let a = NSColor(r: 50, g: 100, b: 200)
        let b = NSColor(r: 220, g: 220, b: 220)
        let direct = a.APCACompliance(with: b)
        let alias = a.toAPCACompliance(with: b)
        XCTAssertEqual(direct.level, alias.level)
        XCTAssertEqual(direct.value, alias.value, accuracy: 0.001)
    }
}
