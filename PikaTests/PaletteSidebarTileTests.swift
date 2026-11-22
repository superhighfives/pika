@testable import Pika
import XCTest

/// The sidebar's swatch tiles are sized so the grid ends half a row in, showing that it scrolls.
final class PaletteSidebarTileTests: XCTestCase {
    private let inset: CGFloat = 4

    func testTooShortFallsBackToTheDefaultTile() {
        XCTAssertEqual(PaletteSidebar.tileHeight(showingHalfRowIn: 0), 34)
        XCTAssertEqual(PaletteSidebar.tileHeight(showingHalfRowIn: 4), 34)
        XCTAssertEqual(PaletteSidebar.tileHeight(showingHalfRowIn: -20), 34)
    }

    func testTilesStayWithinTheirLimits() {
        for height in stride(from: 5 as CGFloat, through: 2000, by: 7) {
            let tile = PaletteSidebar.tileHeight(showingHalfRowIn: height)
            XCTAssertGreaterThanOrEqual(tile, 28, "height \(height)")
            XCTAssertLessThanOrEqual(tile, 44, "height \(height)")
        }
    }

    /// Two and a half rows would need tiles under the 28pt floor here, so they stop at 28.
    func testShortSidebarsStopAtTheSmallestTile() {
        XCTAssertEqual(PaletteSidebar.tileHeight(showingHalfRowIn: 120), 28)
    }

    func testEndsHalfARowIn() {
        for height: CGFloat in [200, 260, 333, 400, 517, 640, 900] {
            let tile = PaletteSidebar.tileHeight(showingHalfRowIn: height)
            XCTAssert((28 ... 44).contains(tile) && tile != 28 && tile != 44, "clamped at height \(height)")
            let rows = (height - inset) / (tile + PaletteSidebar.rowExtras)
            XCTAssertEqual(rows - rows.rounded(.down), 0.5, accuracy: 0.001, "height \(height)")
        }
    }
}
