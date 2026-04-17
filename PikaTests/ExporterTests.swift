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

    func test_paletteToJSON_outputIsPrettyPrintedAndSorted() {
        // The implementation asks JSONSerialization for both `.prettyPrinted`
        // and `.sortedKeys`. Preserve that contract so CLI diffs of exported
        // palettes stay stable.
        let pair = makePair(fg: "#ff0000", bg: "#00ff00", date: Date(timeIntervalSince1970: 0))
        let json = Exporter.paletteToJSON(pairs: [pair], name: "Brand")
        XCTAssertTrue(json.contains("\n"), "Output should be pretty-printed across multiple lines")
        // `colors` sorts alphabetically before `name` when sortedKeys is on.
        let colorsIndex = json.range(of: "\"colors\"")!.lowerBound
        let nameIndex = json.range(of: "\"name\"")!.lowerBound
        XCTAssertLessThan(colorsIndex, nameIndex, "Keys should be alphabetically sorted")
    }
}
