import Defaults
@testable import Pika
import XCTest

final class ColorDecompositionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Pin the display space so decompose (which reads Defaults[.colorSpace] for
        // rgb/hsb/hsl) is deterministic and matches toFormat.
        Defaults[.colorSpace] = .sRGB
    }

    private let samples = ["3A7BD5", "E32C88", "000000", "FFFFFF", "808080", "FF8800", "00FF00", "123456"]
    private var space: NSColorSpace { Defaults[.colorSpace] }

    // MARK: - Parity: decompose(...).joined() must equal toFormat(...)

    func test_decompose_joined_matchesToFormat_forEveryFormatAndStyle() {
        for hex in samples {
            let color = NSColor(hex: hex)
            for format in ColorFormat.allCases {
                for style in CopyFormat.allCases {
                    let expected = color.toFormat(format: format, style: style)
                    let decomposed = format.decompose(color, style: style, in: space)
                    XCTAssertEqual(
                        decomposed.joined(), expected,
                        "Parity failed for \(hex) format=\(format) style=\(style)"
                    )
                }
            }
        }
    }

    func test_decompose_componentCount_isOneForHex_threeOtherwise() {
        let color = NSColor(hex: "3A7BD5")
        for style in CopyFormat.allCases {
            XCTAssertEqual(ColorFormat.hex.decompose(color, style: style, in: space).components.count, 1)
            for format in ColorFormat.allCases where format != .hex {
                XCTAssertEqual(
                    format.decompose(color, style: style, in: space).components.count, 3,
                    "\(format)/\(style) should have 3 components"
                )
            }
        }
    }

    // MARK: - Round-trip: decompose → recompose lands on (near) the same colour

    func test_decompose_recompose_roundTrip_withinTolerance() {
        for hex in samples {
            let color = NSColor(hex: hex)
            for format in ColorFormat.allCases {
                for style in CopyFormat.allCases {
                    let decomposed = format.decompose(color, style: style, in: space)
                    guard let rebuilt = format.recompose(decomposed.values, style: style, in: space) else {
                        XCTFail("recompose returned nil for \(hex) \(format)/\(style)")
                        continue
                    }
                    let o = color.toRGBAComponents(in: .sRGB)
                    let r = rebuilt.toRGBAComponents(in: .sRGB)
                    // hex/rgb are exact 8-bit; hsb/hsl/lab/oklch snap by up to ~1 display unit.
                    let tol: CGFloat = (format == .hex || format == .rgb) ? 0.01 : 0.02
                    XCTAssertEqual(r.r, o.r, accuracy: tol, "R \(hex) \(format)/\(style)")
                    XCTAssertEqual(r.g, o.g, accuracy: tol, "G \(hex) \(format)/\(style)")
                    XCTAssertEqual(r.b, o.b, accuracy: tol, "B \(hex) \(format)/\(style)")
                }
            }
        }
    }

    // MARK: - recompose rejects bad input

    func test_recompose_nonNumeric_returnsNil() {
        XCTAssertNil(ColorFormat.rgb.recompose(["255", "abc", "0"], style: .css, in: space))
        XCTAssertNil(ColorFormat.hsl.recompose(["", "50", "50"], style: .css, in: space))
        XCTAssertNil(ColorFormat.hex.recompose(["nothex"], style: .css, in: space))
    }

    func test_recompose_wrongComponentCount_returnsNil() {
        XCTAssertNil(ColorFormat.rgb.recompose(["255", "0"], style: .css, in: space))
        XCTAssertNil(ColorFormat.oklch.recompose(["50"], style: .css, in: space))
    }

    func test_recompose_outOfRange_clampsRatherThanFails() {
        // Over-range ints still produce a colour (clamped), not nil.
        let white = ColorFormat.rgb.recompose(["999", "999", "999"], style: .css, in: space)
        XCTAssertNotNil(white)
        let rgba = white!.toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rgba.r, 1.0, accuracy: 0.01)
    }

    // Regression test: the committed colour must match what `finalizeValues` snaps the
    // field's displayed text to — an out-of-range Lab `l` or OKLCH `l`/`c`/`h` used to be passed
    // straight through to `fromLab`/`fromOklch` unclamped, silently committing a colour that
    // disagreed with the clamped value shown in the UI.
    func test_recompose_outOfRange_clampsForLabAndOklch() {
        let labOverRange = ColorFormat.lab.recompose(["1000", "50", "0"], style: .css, in: space)
        let labClamped = ColorFormat.lab.recompose(["100", "50", "0"], style: .css, in: space)
        XCTAssertNotNil(labOverRange)
        XCTAssertEqual(
            labOverRange?.toHex(in: .sRGB), labClamped?.toHex(in: .sRGB),
            "an out-of-range Lab l should commit the same colour the clamped display value shows"
        )

        let oklchOverRange = ColorFormat.oklch.recompose(["50", "0.1", "400"], style: .css, in: space)
        let oklchClamped = ColorFormat.oklch.recompose(["50", "0.1", "360"], style: .css, in: space)
        XCTAssertNotNil(oklchOverRange)
        XCTAssertEqual(
            oklchOverRange?.toHex(in: .sRGB), oklchClamped?.toHex(in: .sRGB),
            "an out-of-range OKLCH h must clamp (matching the displayed value), not wrap via cos/sin"
        )
    }

    // MARK: - ColorComponent validity

    func test_componentValidity_integerRange() {
        let c = ColorComponent(value: "128", kind: .integer, range: 0 ... 255)
        XCTAssertTrue(c.isValid("0"))
        XCTAssertTrue(c.isValid("255"))
        // Out-of-range numbers are still valid input — they're clamped to the nearest bound on
        // commit (see `EditableColorValue.finalizeValues`) rather than rejected outright.
        XCTAssertTrue(c.isValid("256"))
        XCTAssertTrue(c.isValid("-1"))
        XCTAssertFalse(c.isValid("12.5"))
        XCTAssertFalse(c.isValid("abc"))
        XCTAssertFalse(c.isValid(""))
    }

    func test_componentValidity_hex() {
        let c = ColorComponent(value: "ff0000", kind: .hex, range: nil)
        XCTAssertTrue(c.isValid("ff0000"))
        XCTAssertTrue(c.isValid("F00"))
        XCTAssertFalse(c.isValid("ff00"))
        XCTAssertFalse(c.isValid("gggggg"))
    }

    // Regression test: pasting a hex value with surrounding whitespace shouldn't flag the
    // field invalid or fail to recompose — `isValid` and `recompose` both trim first.
    func test_componentValidity_hex_trimsWhitespace() {
        let c = ColorComponent(value: "ff0000", kind: .hex, range: nil)
        XCTAssertTrue(c.isValid("  ff0000  "))
        XCTAssertNotNil(ColorFormat.hex.recompose(["  ff0000  "], style: .css, in: space))
    }

    func test_componentValidity_decimalUnbounded() {
        let c = ColorComponent(value: "-12.5", kind: .decimal, range: nil)
        XCTAssertTrue(c.isValid("-12.5"))
        XCTAssertTrue(c.isValid("100"))
        XCTAssertFalse(c.isValid("abc"))
    }

    // Same "clamped, not rejected" rule as `.integer` — see test_componentValidity_integerRange.
    func test_componentValidity_decimalRange() {
        let c = ColorComponent(value: "0.5", kind: .decimal, range: 0 ... 1)
        XCTAssertTrue(c.isValid("0"))
        XCTAssertTrue(c.isValid("1"))
        XCTAssertTrue(c.isValid("1.5"))
        XCTAssertTrue(c.isValid("-0.5"))
    }

    // `Double("inf")`/`Double("nan")` parse successfully but aren't valid colour values — a nil
    // range (e.g. Lab a/b) wouldn't otherwise reject them, so `isValid` must check `isFinite`
    // explicitly. Regression test for a non-finite value silently reaching `recompose`.
    func test_componentValidity_decimalRejectsInfAndNaN() {
        let unbounded = ColorComponent(value: "0", kind: .decimal, range: nil)
        XCTAssertFalse(unbounded.isValid("inf"))
        XCTAssertFalse(unbounded.isValid("-inf"))
        XCTAssertFalse(unbounded.isValid("nan"))

        let bounded = ColorComponent(value: "0", kind: .decimal, range: 0 ... 100)
        XCTAssertFalse(bounded.isValid("inf"))
        XCTAssertFalse(bounded.isValid("nan"))
    }
}
