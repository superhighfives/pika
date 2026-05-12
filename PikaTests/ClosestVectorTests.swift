@testable import Pika
import XCTest

/// Tests the Euclidean-distance nearest-neighbour lookup used to resolve a
/// picked color to its closest named color. Regressions here would show up
/// as wrong color names in the UI and in exported JSON.
final class ClosestVectorTests: XCTestCase {
    // MARK: - diff()

    func test_diff_identicalVectors_isZero() {
        let cv = ClosestVector([[0, 0, 0]])
        XCTAssertEqual(cv.diff([128, 64, 32], [128, 64, 32]), 0)
    }

    func test_diff_isSquaredEuclidean() {
        let cv = ClosestVector([[0, 0, 0]])
        // (10-0)^2 + (0-0)^2 + (0-0)^2 = 100
        XCTAssertEqual(cv.diff([10, 0, 0], [0, 0, 0]), 100)
        // (1-4)^2 + (2-6)^2 + (3-15)^2 = 9 + 16 + 144 = 169
        XCTAssertEqual(cv.diff([1, 2, 3], [4, 6, 15]), 169)
    }

    func test_diff_isSymmetric() {
        let cv = ClosestVector([[0, 0, 0]])
        XCTAssertEqual(cv.diff([12, 34, 56], [78, 90, 12]),
                       cv.diff([78, 90, 12], [12, 34, 56]))
    }

    func test_diff_handlesNegativeDifferences() {
        let cv = ClosestVector([[0, 0, 0]])
        // Subtractions squared — sign of the difference must not matter.
        XCTAssertEqual(cv.diff([0, 0, 0], [10, 10, 10]),
                       cv.diff([10, 10, 10], [0, 0, 0]))
    }

    // MARK: - compare()

    func test_compare_exactMatch_returnsThatIndex() {
        let cv = ClosestVector([[255, 0, 0], [0, 255, 0], [0, 0, 255]])
        let green = NSColor(red: 0, green: 1, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(cv.compare(green), 1)
    }

    func test_compare_returnsNearestNeighbour() {
        // Pure red is closer to [250, 5, 5] than to either green or blue.
        let cv = ClosestVector([[0, 255, 0], [250, 5, 5], [0, 0, 255]])
        let red = NSColor(red: 1, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(cv.compare(red), 1)
    }

    func test_compare_tie_returnsFirstIndexEncountered() {
        // Two entries equidistant from pure black — the loop uses strict `<`,
        // so the first entry inserted wins.
        let cv = ClosestVector([[10, 0, 0], [0, 10, 0]])
        let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(cv.compare(black), 0)
    }

    func test_compare_singleEntryList_alwaysReturnsZero() {
        let cv = ClosestVector([[128, 128, 128]])
        let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1).usingColorSpace(.sRGB)!
        XCTAssertEqual(cv.compare(white), 0)
    }

    func test_compare_normalizesColorToSRGB() {
        // A Display P3 red should still resolve to the sRGB-red bucket after
        // the internal `usingColorSpace(.sRGB)` normalisation.
        let cv = ClosestVector([[0, 0, 0], [255, 0, 0], [0, 255, 0]])
        let p3Red = NSColor(colorSpace: .displayP3, components: [1.0, 0.0, 0.0, 1.0], count: 4)
        XCTAssertEqual(cv.compare(p3Red), 1)
    }
}
