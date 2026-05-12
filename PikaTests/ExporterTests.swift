@testable import Pika
import XCTest

/// Tests the palette-to-JSON export contract. Users rely on this format when
/// exporting swatches, so the shape and field names are a public contract.
///
/// `Exporter.toText` and `Exporter.toJSON` take `Eyedropper` values whose
/// initialiser force-unwraps `loadColors()`, which reads `ColorNames.json`
/// from `Bundle.main`. That bundle is not populated in the XCTest host, so
/// those paths are out of reach from a unit test without an app-bundle
/// fixture. Coverage for them belongs in an integration/UI test target.
final class ExporterTests: XCTestCase {
    private func makePair(fg: String, bg: String, date: Date) -> ColorPair {
        ColorPair(id: UUID(), foregroundHex: fg, backgroundHex: bg, date: date)
    }

    private func decode(_ json: String) throws -> [String: Any] {
        let data = try XCTUnwrap(json.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(obj as? [String: Any])
    }

    // MARK: - paletteToJSON: named palette

    func test_paletteToJSON_namedPalette_usesProvidedName() throws {
        let pair = makePair(fg: "#ff0000", bg: "#00ff00", date: Date(timeIntervalSince1970: 0))
        let json = Exporter.paletteToJSON(pairs: [pair], name: "Brand")
        let parsed = try decode(json)
        XCTAssertEqual(parsed["name"] as? String, "Brand")
    }

    func test_paletteToJSON_namedPalette_omitsDateField() throws {
        // Named palettes intentionally strip creation dates — users shouldn't
        // see internal timestamps in shareable exports.
        let pair = makePair(fg: "#ff0000", bg: "#00ff00", date: Date(timeIntervalSince1970: 1_700_000_000))
        let json = Exporter.paletteToJSON(pairs: [pair], name: "Brand")
        let parsed = try decode(json)
        let colors = try XCTUnwrap(parsed["colors"] as? [[String: String]])
        XCTAssertEqual(colors.count, 1)
        XCTAssertNil(colors[0]["date"])
        XCTAssertEqual(colors[0]["foreground"], "#ff0000")
        XCTAssertEqual(colors[0]["background"], "#00ff00")
    }

    // MARK: - paletteToJSON: auto-history (nil name)

    func test_paletteToJSON_nilName_fallsBackToColorHistoryLabel() throws {
        let pair = makePair(fg: "#ff0000", bg: "#00ff00", date: Date(timeIntervalSince1970: 0))
        let json = Exporter.paletteToJSON(pairs: [pair], name: nil)
        let parsed = try decode(json)
        XCTAssertEqual(parsed["name"] as? String, "Color History")
    }

    func test_paletteToJSON_nilName_includesISO8601Dates() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let pair = makePair(fg: "#123456", bg: "#abcdef", date: date)
        let json = Exporter.paletteToJSON(pairs: [pair], name: nil)
        let parsed = try decode(json)
        let colors = try XCTUnwrap(parsed["colors"] as? [[String: String]])
        XCTAssertEqual(colors.count, 1)

        let dateString = try XCTUnwrap(colors[0]["date"])
        let parsedDate = try XCTUnwrap(ISO8601DateFormatter().date(from: dateString))
        XCTAssertEqual(parsedDate.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - paletteToJSON: ordering and shape

    func test_paletteToJSON_preservesOrderOfPairs() throws {
        let pairs = [
            makePair(fg: "#111111", bg: "#222222", date: Date(timeIntervalSince1970: 0)),
            makePair(fg: "#333333", bg: "#444444", date: Date(timeIntervalSince1970: 1)),
            makePair(fg: "#555555", bg: "#666666", date: Date(timeIntervalSince1970: 2)),
        ]
        let json = Exporter.paletteToJSON(pairs: pairs, name: "Ordered")
        let parsed = try decode(json)
        let colors = try XCTUnwrap(parsed["colors"] as? [[String: String]])
        XCTAssertEqual(colors.map { $0["foreground"] }, ["#111111", "#333333", "#555555"])
        XCTAssertEqual(colors.map { $0["background"] }, ["#222222", "#444444", "#666666"])
    }

    func test_paletteToJSON_emptyPairs_producesEmptyColorsArray() throws {
        let json = Exporter.paletteToJSON(pairs: [], name: "Empty")
        let parsed = try decode(json)
        let colors = try XCTUnwrap(parsed["colors"] as? [[String: String]])
        XCTAssertEqual(parsed["name"] as? String, "Empty")
        XCTAssertTrue(colors.isEmpty)
    }

    func test_paletteToJSON_outputIsPrettyPrintedAndSorted() throws {
        // The implementation asks JSONSerialization for both `.prettyPrinted`
        // and `.sortedKeys`. Preserve that contract so CLI diffs of exported
        // palettes stay stable.
        let pair = makePair(fg: "#ff0000", bg: "#00ff00", date: Date(timeIntervalSince1970: 0))
        let json = Exporter.paletteToJSON(pairs: [pair], name: "Brand")
        XCTAssertTrue(json.contains("\n"), "Output should be pretty-printed across multiple lines")
        // `colors` sorts alphabetically before `name` when sortedKeys is on.
        let colorsRange = try XCTUnwrap(json.range(of: "\"colors\""))
        let nameRange = try XCTUnwrap(json.range(of: "\"name\""))
        XCTAssertLessThan(colorsRange.lowerBound, nameRange.lowerBound,
                          "Keys should be alphabetically sorted")
    }

    // MARK: - RAL model decoding

    func test_ralResponseData_decodesSnakeCaseNameKeys() throws {
        let json = #"""
        {
            "colors": [
                {
                    "code": "RAL 1000",
                    "name_en": "Green beige",
                    "name_zh": "绿色米色",
                    "hex": "#CCC58F"
                }
            ]
        }
        """#

        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(RALResponseData.self, from: data)
        XCTAssertEqual(decoded.colors.count, 1)

        let first = try XCTUnwrap(decoded.colors.first)
        XCTAssertEqual(first.code, "RAL 1000")
        XCTAssertEqual(first.nameEn, "Green beige")
        XCTAssertEqual(first.nameZh, "绿色米色")
        XCTAssertEqual(first.hex, "#CCC58F")
    }

    func test_ralColorName_colorParsesHex() throws {
        let json = #"""
        {
            "colors": [
                {
                    "code": "RAL 3020",
                    "name_en": "Traffic red",
                    "name_zh": "交通红",
                    "hex": "#C1121C"
                }
            ]
        }
        """#

        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(RALResponseData.self, from: data)
        let color = try XCTUnwrap(XCTUnwrap(decoded.colors.first).color.usingColorSpace(.sRGB))

        XCTAssertEqual(color.redComponent, 193.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(color.greenComponent, 18.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(color.blueComponent, 28.0 / 255.0, accuracy: 0.01)
    }
}
