@testable import Pika
import XCTest

/// Tests the generic `unique()` helper on Sequence. Used by history and
/// palette code to de-duplicate color entries while preserving order.
final class SequenceTests: XCTestCase {
    func test_unique_emptySequence_returnsEmpty() {
        let result: [Int] = [].unique()
        XCTAssertEqual(result, [])
    }

    func test_unique_allDistinct_preservesOrderAndCount() {
        XCTAssertEqual([1, 2, 3, 4].unique(), [1, 2, 3, 4])
    }

    func test_unique_removesDuplicates_preservingFirstOccurrence() {
        XCTAssertEqual([1, 2, 1, 3, 2, 4].unique(), [1, 2, 3, 4])
    }

    func test_unique_allIdentical_returnsSingleElement() {
        XCTAssertEqual([7, 7, 7, 7].unique(), [7])
    }

    func test_unique_onStrings() {
        XCTAssertEqual(["a", "b", "a", "c", "b"].unique(), ["a", "b", "c"])
    }

    func test_unique_onHexLikeStrings_caseSensitive() {
        // #FF0000 and #ff0000 are different hashables — de-duplication must
        // respect case so we don't silently merge distinct entries.
        XCTAssertEqual(["#ff0000", "#FF0000", "#ff0000"].unique(), ["#ff0000", "#FF0000"])
    }

    func test_unique_doesNotMutateSource() {
        let source = [1, 1, 2, 2, 3]
        _ = source.unique()
        XCTAssertEqual(source, [1, 1, 2, 2, 3])
    }
}
