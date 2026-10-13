@testable import Pika
import XCTest

final class NSColorLabTests: XCTestCase {
    // MARK: - toOpenGLString(style:)

    func test_toOpenGLString_cssStyle_containsRGBA() {
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let result = red.toOpenGLString(style: .css)
        XCTAssertTrue(result.hasPrefix("rgba("))
        XCTAssertTrue(result.contains("1.0)"))
    }

    func test_toOpenGLString_unformattedStyle_noParens() {
        let color = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = color.toOpenGLString(style: .unformatted)
        XCTAssertFalse(result.contains("rgba("))
    }

    func test_toOpenGLString_valuesNormalized() {
        // OpenGL uses 0–1 range; red should give r≈1, g≈0, b≈0
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let result = red.toOpenGLString(style: .css)
        XCTAssertTrue(result.contains("1"))
    }

    // MARK: - toLabComponents()

    func test_toLabComponents_white_LIsApproximately100() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let lab = white.toLabComponents()
        XCTAssertEqual(lab.l, 100.0, accuracy: 1.0)
    }

    func test_toLabComponents_black_LIsApproximatelyZero() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let lab = black.toLabComponents()
        XCTAssertEqual(lab.l, 0.0, accuracy: 1.0)
    }

    func test_toLabComponents_gray_AAndBNearZero() {
        // Neutral gray should have a ≈ 0, b ≈ 0
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let lab = gray.toLabComponents()
        XCTAssertEqual(lab.a, 0.0, accuracy: 2.0)
        XCTAssertEqual(lab.b, 0.0, accuracy: 2.0)
    }

    func test_toLabComponents_LIsInValidRange() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let lab = color.toLabComponents()
        XCTAssertGreaterThanOrEqual(lab.l, 0.0)
        XCTAssertLessThanOrEqual(lab.l, 100.0)
    }

    // MARK: - toLabString(style:)

    func test_toLabString_cssStyle_containsLabPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toLabString(style: .css)
        XCTAssertTrue(result.hasPrefix("lab("), "Expected 'lab(...)', got '\(result)'")
    }

    func test_toLabString_unformattedStyle_noLabPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toLabString(style: .unformatted)
        XCTAssertFalse(result.contains("lab("))
    }

    func test_toLabString_returnsNonEmptyString() {
        let color = NSColor(r: 200, g: 100, b: 50)
        XCTAssertFalse(color.toLabString().isEmpty)
    }

    // MARK: - toOklchComponents()

    func test_toOklchComponents_white_LIsApproximatelyOne() {
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = white.toOklchComponents()
        XCTAssertEqual(oklch.l, 1.0, accuracy: 0.01)
    }

    func test_toOklchComponents_black_LIsApproximatelyZero() {
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = black.toOklchComponents()
        XCTAssertEqual(oklch.l, 0.0, accuracy: 0.01)
    }

    func test_toOklchComponents_gray_chromaIsLow() {
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let oklch = gray.toOklchComponents()
        XCTAssertLessThan(oklch.c, 0.01)
    }

    func test_toOklchComponents_LIsInValidRange() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let oklch = color.toOklchComponents()
        XCTAssertGreaterThanOrEqual(oklch.l, 0.0)
        XCTAssertLessThanOrEqual(oklch.l, 1.0)
    }

    func test_toOklchComponents_achromatic_hueIsZero() {
        // Hue is meaningless without chroma; atan2 of float noise gave white a hue of 89.88.
        for value in [0.0, 0.5, 1.0] {
            let gray = NSColor(red: value, green: value, blue: value, alpha: 1).usingColorSpace(.sRGB)!
            XCTAssertEqual(gray.toOklchComponents().h, 0, "gray \(value)")
        }
        XCTAssertEqual(NSColor.white.usingColorSpace(.sRGB)!.toOklchString(style: .css), "oklch(100% 0 0)")
    }

    func test_toOklchComponents_chromatic_keepsHue() {
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(blue.toOklchComponents().h, 264.05, accuracy: 0.01)
    }

    // MARK: - toOklchString(style:)

    func test_toOklchString_cssStyle_containsOklchPrefix() {
        let color = NSColor(r: 100, g: 150, b: 200)
        let result = color.toOklchString(style: .css)
        XCTAssertTrue(result.hasPrefix("oklch("), "Expected 'oklch(...)', got '\(result)'")
    }

    func test_toOklchString_returnsNonEmptyString() {
        let color = NSColor(r: 50, g: 100, b: 200)
        XCTAssertFalse(color.toOklchString().isEmpty)
    }

    func test_toOklchString_achromatic_noTrailingZerosOnChroma() {
        // Gray has chroma ≈ 0; the formatted chroma should not end in trailing zeros
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = gray.toOklchString(style: .css)
        // Extract chroma token: oklch(L% C H)
        let tokens = String(result.dropFirst("oklch(".count).dropLast(1)).components(separatedBy: " ")
        XCTAssertEqual(tokens.count, 3)
        let chroma = tokens[1]
        XCTAssertFalse(chroma.contains(".") && chroma.hasSuffix("0"),
                       "Chroma '\(chroma)' has trailing zeros after decimal")
    }

    func test_toOklchString_chromatic_stripsTrailingZerosWherePresent() {
        // A color whose chroma rounds to a value with trailing zeros (e.g. exactly 0.1000)
        // should not show them, while one with significant digits should keep them
        let blue = NSColor(red: 0, green: 0, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        let result = blue.toOklchString(style: .css)
        XCTAssertTrue(result.hasPrefix("oklch("))
        // No token should end in a trailing zero after the decimal
        let tokens = String(result.dropFirst("oklch(".count).dropLast(1)).components(separatedBy: " ")
        for token in tokens {
            XCTAssertFalse(token.contains(".") && token.hasSuffix("0"),
                           "Token '\(token)' has trailing zeros after decimal")
        }
    }

    func test_toOklchString_unformatted_noTrailingZeros() {
        let gray = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).usingColorSpace(.sRGB)!
        let result = gray.toOklchString(style: .unformatted)
        let tokens = result.components(separatedBy: ", ")
        for token in tokens {
            XCTAssertFalse(token.contains(".") && token.hasSuffix("0"),
                           "Token '\(token)' has trailing zeros after decimal")
        }
    }

    // MARK: - fromLab(l:a:b:) — inverse round-trips

    private let roundTripSamples = ["3A7BD5", "E32C88", "00FF00", "808080", "FF8800", "123456"]

    func test_fromLab_roundTrip_matchesOriginalRGB() {
        for hex in roundTripSamples {
            let original = NSColor(hex: hex).usingColorSpace(.sRGB)!
            let lab = original.toLabComponents()
            let rebuilt = NSColor.fromLab(l: lab.l, a: lab.a, b: lab.b).usingColorSpace(.sRGB)!
            let o = original.toRGBAComponents(in: .sRGB)
            let r = rebuilt.toRGBAComponents(in: .sRGB)
            XCTAssertEqual(r.r, o.r, accuracy: 0.01, "R mismatch for \(hex)")
            XCTAssertEqual(r.g, o.g, accuracy: 0.01, "G mismatch for \(hex)")
            XCTAssertEqual(r.b, o.b, accuracy: 0.01, "B mismatch for \(hex)")
        }
    }

    func test_fromLab_white_isWhite() {
        let rebuilt = NSColor.fromLab(l: 100, a: 0, b: 0).toRGBAComponents(in: .sRGB)
        XCTAssertEqual(rebuilt.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rebuilt.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(rebuilt.b, 1.0, accuracy: 0.01)
    }

    // MARK: - fromOklch(l:c:h:) — inverse round-trips

    func test_fromOklch_roundTrip_matchesOriginalRGB() {
        for hex in roundTripSamples {
            let original = NSColor(hex: hex).usingColorSpace(.sRGB)!
            let oklch = original.toOklchComponents()
            let rebuilt = NSColor.fromOklch(l: oklch.l, c: oklch.c, h: oklch.h).usingColorSpace(.sRGB)!
            let o = original.toRGBAComponents(in: .sRGB)
            let r = rebuilt.toRGBAComponents(in: .sRGB)
            XCTAssertEqual(r.r, o.r, accuracy: 0.01, "R mismatch for \(hex)")
            XCTAssertEqual(r.g, o.g, accuracy: 0.01, "G mismatch for \(hex)")
            XCTAssertEqual(r.b, o.b, accuracy: 0.01, "B mismatch for \(hex)")
        }
    }

    // MARK: - Wide gamut (Lab and OKLCH are carried as unclamped extended sRGB)

    func test_fromOklch_outOfGamut_clampsOnlyWhenReadAsSRGB() {
        // A wildly out-of-gamut OKLCH still reads as in-[0,1] sRGB channels (hex, RGB, contrast),
        // not NaN/overflow, while the colour itself keeps what was asked for.
        let color = NSColor.fromOklch(l: 0.7, c: 0.4, h: 30)
        let srgb = color.toRGBAComponents(in: .sRGB)
        for channel in [srgb.r, srgb.g, srgb.b] {
            XCTAssertGreaterThanOrEqual(channel, 0.0)
            XCTAssertLessThanOrEqual(channel, 1.0)
        }
        XCTAssertEqual(color.toOklchComponents().c, 0.4, accuracy: 0.0001)
    }

    /// The reported case: chroma 0.2 at L 30%, H 230° used to land on 0.1371.
    func test_oklch_outsideSRGB_keepsTheAuthoredValue() {
        let color = NSColor.fromOklch(l: 0.3, c: 0.2, h: 230)
        XCTAssertEqual(color.toOklchString(style: .css), "oklch(30% 0.2 230)")
        XCTAssertEqual(ColorFormat.oklch.decompose(color, style: .css, in: .sRGB).values, ["30", "0.2", "230"])
    }

    func test_oklch_roundTripsAcrossAGridIncludingOutOfGamutValues() {
        for l in stride(from: 0.1, through: 0.9, by: 0.2) {
            for c in stride(from: 0.05, through: 0.4, by: 0.07) {
                for h in stride(from: 0.0, to: 360.0, by: 30) {
                    let back = NSColor.fromOklch(l: l, c: c, h: h).toOklchComponents()
                    XCTAssertEqual(back.l, l, accuracy: 0.00005, "L for \(l) \(c) \(h)")
                    XCTAssertEqual(back.c, c, accuracy: 0.00005, "C for \(l) \(c) \(h)")
                    XCTAssertEqual(back.h, h, accuracy: 0.005, "H for \(l) \(c) \(h)")
                }
            }
        }
    }

    func test_lab_roundTripsAcrossAGridIncludingOutOfGamutValues() {
        for l in stride(from: 10.0, through: 90.0, by: 20) {
            for a in stride(from: -120.0, through: 120.0, by: 60) {
                for b in stride(from: -120.0, through: 120.0, by: 60) {
                    let back = NSColor.fromLab(l: l, a: a, b: b).toLabComponents()
                    XCTAssertEqual(back.l, l, accuracy: 0.005, "L for \(l) \(a) \(b)")
                    XCTAssertEqual(back.a, a, accuracy: 0.005, "a for \(l) \(a) \(b)")
                    XCTAssertEqual(back.b, b, accuracy: 0.005, "b for \(l) \(a) \(b)")
                }
            }
        }
    }

    func test_lab_outsideSRGB_keepsTheAuthoredValue() {
        let color = NSColor.fromLab(l: 50, a: -100, b: 60)
        XCTAssertEqual(color.toLabString(style: .css), "lab(50 -100 60)")
    }

    /// A Display P3 colour outside sRGB reports its own OKLCH, not that of its sRGB neighbour.
    func test_oklch_ofAP3Colour_isNotTheClampedSRGBValue() {
        let p3Red = NSColor(colorSpace: .displayP3, components: [1, 0, 0, 1], count: 4)
        let stored = p3Red.usingColorSpace(.extendedSRGB)!
        let srgbRed = NSColor(colorSpace: .sRGB, components: [1, 0, 0, 1], count: 4)
        XCTAssertGreaterThan(stored.toOklchComponents().c, srgbRed.toOklchComponents().c + 0.02)
    }

    // MARK: - Display gamut

    func test_isDisplayable_sRGBColoursFitBothGamuts() {
        for hex in ["#000000", "#ffffff", "#ff0000", "#00ff00", "#0000ff", "#8a2be2", "#7f7f7f"] {
            let color = NSColor.fromHex(hex, in: .sRGB)!
            XCTAssertTrue(color.isDisplayable(in: .sRGB), hex)
            XCTAssertTrue(color.isDisplayable(in: .displayP3), hex)
        }
    }

    func test_isDisplayable_p3PrimariesFitP3ButNotSRGB() {
        for components: [CGFloat] in [[1, 0, 0, 1], [0, 1, 0, 1], [0, 0, 1, 1]] {
            let stored = NSColor(colorSpace: .displayP3, components: components, count: 4)
                .usingColorSpace(.extendedSRGB)!
            XCTAssertTrue(stored.isDisplayable(in: .displayP3), "\(components)")
            XCTAssertFalse(stored.isDisplayable(in: .sRGB), "\(components)")
        }
    }

    func test_isDisplayable_readoutRoundingDoesNotFlagAColourOnTheGamutEdge() {
        // sRGB red, rebuilt from its own rounded OKLCH readout, sits a hair outside sRGB.
        let red = NSColor.fromHex("#ff0000", in: .sRGB)!
        let values = ColorFormat.oklch.decompose(red, style: .css, in: .sRGB).values
        let rebuilt = ColorFormat.oklch.recompose(values, style: .css, in: .sRGB)!
        XCTAssertTrue(rebuilt.isDisplayable(in: .sRGB))
    }

    func test_isDisplayable_authoredOklchOutsideEachGamut() {
        // The reported colour is outside sRGB.
        XCTAssertFalse(NSColor.fromOklch(l: 0.3, c: 0.2, h: 230).isDisplayable(in: .sRGB))
        // Far beyond either.
        let extreme = NSColor.fromOklch(l: 0.9, c: 0.4, h: 150)
        XCTAssertFalse(extreme.isDisplayable(in: .sRGB))
        XCTAssertFalse(extreme.isDisplayable(in: .displayP3))
    }

    /// Contrast is scored on the colour the screen shows, never the unclamped one.
    func test_luminance_ofAnOutOfGamutColour_isThatOfItsClampedSRGBColour() {
        let wide = NSColor.fromOklch(l: 0.7, c: 0.4, h: 30)
        let clamped = wide.usingColorSpace(.sRGB)!
        XCTAssertEqual(wide.luminance, clamped.luminance, accuracy: 0.0001)
    }
}

// MARK: - Clamping where a format can't hold the colour

extension NSColorLabTests {
    /// Pins the clamp itself, independently of `usingColorSpace`: luminance matches the WCAG
    /// formula over the extended components clipped to 0–1 by hand.
    func test_luminance_ofAnOutOfGamutColour_matchesHandClippedComponents() {
        let wide = NSColor.fromOklch(l: 0.7, c: 0.4, h: 30)
        let ext = wide.toRGBAComponents(in: .extendedSRGB)
        XCTAssertTrue([ext.r, ext.g, ext.b].contains { $0 < 0 || $0 > 1 }, "fixture should be outside sRGB")
        func linear(_ component: CGFloat) -> CGFloat {
            let clipped = min(max(component, 0), 1)
            return clipped < 0.03928 ? clipped / 12.92 : pow((clipped + 0.055) / 1.055, 2.4)
        }
        let expected = 0.2126 * linear(ext.r) + 0.7152 * linear(ext.g) + 0.0722 * linear(ext.b)
        XCTAssertEqual(wide.luminance, expected, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(wide.luminance, 1)
    }

    /// RGB output of a colour outside even Display P3 stays within 0–255.
    func test_toRGB8BitArray_ofAnOutOfGamutColour_staysIn8BitRange() {
        let extreme = NSColor.fromOklch(l: 0.9, c: 0.4, h: 150)
        for space in [NSColorSpace.sRGB, .displayP3] {
            for channel in extreme.toRGB8BitArray(in: space) {
                XCTAssertGreaterThanOrEqual(channel, 0, "\(space)")
                XCTAssertLessThanOrEqual(channel, 255, "\(space)")
            }
        }
    }
}
