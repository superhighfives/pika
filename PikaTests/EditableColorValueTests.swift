@testable import Pika
import XCTest

/// Tests the per-pixel drag/scroll/arrow-key scrub sensitivity used by editable colour
/// component fields. Regressions here would show up as a component's range being impossible
/// to traverse smoothly (too coarse) or maxing out in a single pixel of drag (too fine).
final class EditableColorValueTests: XCTestCase {
    func test_dragUnitsPerPixel_nilRange_isFlatOneUnitPerPixel() {
        XCTAssertEqual(dragUnitsPerPixel(for: nil), 1.0)
    }

    func test_dragUnitsPerPixel_hueRange_isReferenceSpanAndFeelsFlat() {
        // Hue's 0...360 is the reference span itself, so it should still feel like 1 unit/px.
        XCTAssertEqual(dragUnitsPerPixel(for: 0 ... 360), 1.0)
    }

    func test_dragUnitsPerPixel_narrowRange_scalesDownProportionally() {
        // OKLCH chroma's 0...1 is 360x narrower than the reference span.
        XCTAssertEqual(dragUnitsPerPixel(for: 0 ... 1), 1.0 / 360.0)
    }

    func test_dragUnitsPerPixel_wideRange_scalesUpProportionally() {
        // 0...720 is twice the reference span.
        XCTAssertEqual(dragUnitsPerPixel(for: 0 ... 720), 2.0)
    }

    func test_stableDecimalPlaces_noDot_defaultsToTwo() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5"), 2)
    }

    func test_stableDecimalPlaces_trailingDotNoDigits_clampsUpToTwo() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5."), 2)
    }

    func test_stableDecimalPlaces_oneDecimal_clampsUpToTwo() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5.1"), 2)
    }

    func test_stableDecimalPlaces_twoDecimals_keepsTwo() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5.12"), 2)
    }

    func test_stableDecimalPlaces_fourDecimals_keepsFour() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5.1234"), 4)
    }

    func test_stableDecimalPlaces_moreThanFourDecimals_clampsDownToFour() {
        XCTAssertEqual(ColorComponentField.stableDecimalPlaces(for: "5.123456"), 4)
    }
}
