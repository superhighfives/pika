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

    // MARK: - ColorComponent validity

    func test_componentValidity_integerRange() {
        let c = ColorComponent(value: "128", kind: .integer, range: 0 ... 255)
        XCTAssertTrue(c.isValid("0"))
        XCTAssertTrue(c.isValid("255"))
        XCTAssertFalse(c.isValid("256"))
        XCTAssertFalse(c.isValid("-1"))
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

    func test_componentValidity_decimalUnbounded() {
        let c = ColorComponent(value: "-12.5", kind: .decimal, range: nil)
        XCTAssertTrue(c.isValid("-12.5"))
        XCTAssertTrue(c.isValid("100"))
        XCTAssertFalse(c.isValid("abc"))
    }
}
