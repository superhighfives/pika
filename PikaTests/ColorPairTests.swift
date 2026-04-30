import Defaults
@testable import Pika
import XCTest

/// Tests the hex-to-NSColor conversion and round-trip behaviour of ColorPair.
/// ColorPair is the on-disk representation of a swatch in the auto-history
/// and saved palettes, so drift here would corrupt user-visible history.
final class ColorPairTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Defaults[.colorSpace] = .sRGB
    }

    // MARK: - Construction and identity

    func test_equality_ignoresIdAndDate() {
        let lhs = ColorPair(id: UUID(), foregroundHex: "#ff0000", backgroundHex: "#00ff00", date: Date())
        let rhs = ColorPair(id: UUID(), foregroundHex: "#ff0000", backgroundHex: "#00ff00",
                            date: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(lhs, rhs)
    }

    func test_equality_distinguishesByHex() {
        let lhs = ColorPair(id: UUID(), foregroundHex: "#ff0000", backgroundHex: "#00ff00", date: Date())
        let rhs = ColorPair(id: UUID(), foregroundHex: "#ff0001", backgroundHex: "#00ff00", date: Date())
        XCTAssertNotEqual(lhs, rhs)
    }

    // MARK: - foregroundColor / backgroundColor

    func test_foregroundColor_parsesHashedHex() {
        let pair = ColorPair(id: UUID(), foregroundHex: "#ff0000", backgroundHex: "#000000", date: Date())
        let color = pair.foregroundColor.usingColorSpace(.sRGB)!
        XCTAssertEqual(color.redComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
    }

    func test_backgroundColor_parsesUnhashedHex() {
        let pair = ColorPair(id: UUID(), foregroundHex: "#000000", backgroundHex: "0000ff", date: Date())
        let color = pair.backgroundColor.usingColorSpace(.sRGB)!
        XCTAssertEqual(color.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 1.0, accuracy: 0.001)
    }

    func test_hexRoundTrip_noChannelDrift() {
        // Stored hex should reconstruct to a color whose re-serialized hex matches.
        let original = "#3a7bd5"
        let pair = ColorPair(id: UUID(), foregroundHex: original, backgroundHex: "#000000", date: Date())
        XCTAssertEqual(pair.foregroundColor.toHexString(style: .css), original)
    }

    // MARK: - Malformed input

    func test_invalidLength_fallsBackToBlack() {
        let pair = ColorPair(id: UUID(), foregroundHex: "#abc", backgroundHex: "#000000", date: Date())
        let color = pair.foregroundColor.usingColorSpace(.sRGB)!
        XCTAssertEqual(color.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
    }

    func test_emptyHex_fallsBackToBlack() {
        let pair = ColorPair(id: UUID(), foregroundHex: "", backgroundHex: "#000000", date: Date())
        let color = pair.foregroundColor.usingColorSpace(.sRGB)!
        XCTAssertEqual(color.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
    }

    func test_nonHexCharacters_fallBackToBlack() {
        let pair = ColorPair(id: UUID(), foregroundHex: "#zzzzzz", backgroundHex: "#000000", date: Date())
        let color = pair.foregroundColor.usingColorSpace(.sRGB)!
        XCTAssertEqual(color.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
    }

    // MARK: - Codable

    func test_isCodable_roundTripsThroughJSON() throws {
        let original = ColorPair(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            foregroundHex: "#123456",
            backgroundHex: "#abcdef",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ColorPair.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.foregroundHex, original.foregroundHex)
        XCTAssertEqual(decoded.backgroundHex, original.backgroundHex)
        XCTAssertEqual(decoded.date.timeIntervalSince1970, original.date.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Palette

    func test_palette_isAutoHistory_whenNameIsNil() {
        let palette = Palette(id: UUID(), name: nil, pairs: [], createdAt: Date())
        XCTAssertTrue(palette.isAutoHistory)
    }

    func test_palette_isAutoHistory_falseWhenNamed() {
        let palette = Palette(id: UUID(), name: "Brand", pairs: [], createdAt: Date())
        XCTAssertFalse(palette.isAutoHistory)
    }

    func test_maxHistory_is20() {
        // Changing this bound without auditing the history/undo stack truncation
        // logic in Eyedroppers would silently drop user data.
        XCTAssertEqual(ColorPair.maxHistory, 20)
    }
}
