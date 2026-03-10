@testable import Pika
import XCTest

final class CGFloatFormatTests: XCTestCase {
    func test_strippedDecimalString_trailingZerosRemoved() {
        XCTAssertEqual(CGFloat(0.5000).strippedDecimalString(maxDecimalPlaces: 4), "0.5")
        XCTAssertEqual(CGFloat(0.1000).strippedDecimalString(maxDecimalPlaces: 4), "0.1")
        XCTAssertEqual(CGFloat(1.2300).strippedDecimalString(maxDecimalPlaces: 4), "1.23")
    }

    func test_strippedDecimalString_allZerosAfterDecimalRemoved() {
        XCTAssertEqual(CGFloat(0.0000).strippedDecimalString(maxDecimalPlaces: 4), "0")
        XCTAssertEqual(CGFloat(1.0000).strippedDecimalString(maxDecimalPlaces: 4), "1")
        XCTAssertEqual(CGFloat(50.00).strippedDecimalString(maxDecimalPlaces: 2), "50")
    }

    func test_strippedDecimalString_significantDecimalsPreserved() {
        XCTAssertEqual(CGFloat(0.1234).strippedDecimalString(maxDecimalPlaces: 4), "0.1234")
        XCTAssertEqual(CGFloat(56.78).strippedDecimalString(maxDecimalPlaces: 2), "56.78")
    }

    func test_strippedDecimalString_respectsMaxDecimalPlaces() {
        // Should not show more than maxDecimalPlaces significant digits
        XCTAssertEqual(CGFloat(0.12345).strippedDecimalString(maxDecimalPlaces: 3), "0.123")
    }

    func test_strippedDecimalString_negativeValues() {
        XCTAssertEqual(CGFloat(-1.5000).strippedDecimalString(maxDecimalPlaces: 4), "-1.5")
        XCTAssertEqual(CGFloat(-12.3400).strippedDecimalString(maxDecimalPlaces: 4), "-12.34")
    }
}
