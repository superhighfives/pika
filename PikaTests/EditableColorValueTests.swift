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

    // MARK: - Scrub reversibility / gamut clamping

    /// Recomposing from a session's *starting* values is what makes a scrub reversible. Pushing
    /// OKLCH chroma past the sRGB gamut clamps the colour, and decomposing that clamped colour
    /// reports a different lightness and hue — so feeding each frame's result back in would drag
    /// the untouched components along with it and you could never return to where you began.
    func test_scrubFromPristineValues_isReversible() {
        let start = ["40.68", "0.2173", "264.58"]
        let format = ColorFormat.oklch
        let space = NSColorSpace.sRGB

        guard let original = format.recompose(start, style: .css, in: space) else {
            return XCTFail("expected the starting values to recompose")
        }

        // Drag chroma far out of gamut, then back to exactly where it started.
        var pushed = start
        pushed[1] = "1.0"
        guard let clamped = format.recompose(pushed, style: .css, in: space) else {
            return XCTFail("expected the out-of-gamut values to recompose")
        }
        let clampedBack = format.decompose(clamped, style: .css, in: space)
        XCTAssertNotEqual(clampedBack.values[0], start[0], "clamping should have moved lightness")
        XCTAssertNotEqual(clampedBack.values[2], start[2], "clamping should have moved hue")

        // Returning to the original chroma from the pristine starting values restores the colour.
        guard let restored = format.recompose(start, style: .css, in: space) else {
            return XCTFail("expected the restored values to recompose")
        }
        XCTAssertEqual(restored.toHex(in: space), original.toHex(in: space))

        // Whereas carrying the clamped values forward does not.
        var ratcheted = clampedBack.values
        ratcheted[1] = start[1]
        guard let notRestored = format.recompose(ratcheted, style: .css, in: space) else {
            return XCTFail("expected the ratcheted values to recompose")
        }
        XCTAssertNotEqual(notRestored.toHex(in: space), original.toHex(in: space))
    }

    func test_naturalDecimalPlaces_matchesTheStepItCanResolve() {
        XCTAssertEqual(ColorComponentField.naturalDecimalPlaces(forRange: 0 ... 360), 0)
        XCTAssertEqual(ColorComponentField.naturalDecimalPlaces(forRange: 0 ... 100), 1)
        XCTAssertEqual(ColorComponentField.naturalDecimalPlaces(forRange: 0 ... 1), 3)
    }

    // MARK: - Adopting the readout's formatting on commit

    func test_adoptingReadoutFormatting_sameNumber_takesTheReadoutsText() {
        // OpenGL shows `1.0` and five significant digits; the generic commit form had
        // stripped those to `1` and `0.702`.
        let readout = [
            ColorComponent(value: "1.0", kind: .decimal, range: 0 ... 1),
            ColorComponent(value: "0.70196", kind: .decimal, range: 0 ... 1),
        ]
        XCTAssertEqual(
            EditableColorValue.adoptingReadoutFormatting(["1", "0.70196"], readout: readout),
            ["1.0", "0.70196"]
        )
    }

    func test_adoptingReadoutFormatting_differentNumber_keepsTheTypedValue() {
        // HSB hue is undefined at brightness 0, so the committed colour reads back as hue 0;
        // the typed hue must stay rather than being replaced by the readout's.
        let readout = [
            ColorComponent(value: "0", kind: .integer, range: 0 ... 360),
            ColorComponent(value: "0", kind: .integer, range: 0 ... 100),
        ]
        XCTAssertEqual(
            EditableColorValue.adoptingReadoutFormatting(["200", "0"], readout: readout),
            ["200", "0"]
        )
    }

    func test_adoptingReadoutFormatting_withinHalfAUnitOfTheReadout_takesTheReadoutsText() {
        let readout = [ColorComponent(value: "0.702", kind: .decimal, range: 0 ... 1)]
        XCTAssertEqual(EditableColorValue.adoptingReadoutFormatting(["0.7024"], readout: readout), ["0.702"])
        XCTAssertEqual(EditableColorValue.adoptingReadoutFormatting(["0.7026"], readout: readout), ["0.7026"])
    }

    func test_adoptingReadoutFormatting_skipsHexAndMismatchedLayouts() {
        let readout = [
            ColorComponent(value: "abcdef", kind: .hex, range: nil),
            ColorComponent(value: "1.0", kind: .decimal, range: 0 ... 1),
        ]
        XCTAssertEqual(EditableColorValue.adoptingReadoutFormatting(["ABCDEF"], readout: readout), ["ABCDEF"])
    }
}
