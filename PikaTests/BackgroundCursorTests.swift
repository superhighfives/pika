@testable import Pika
import XCTest

/// `BackgroundCursor` leans on two window-server functions that aren't public API. This is the
/// canary: if a macOS release removes or changes them, it fails here rather than as a cursor
/// quietly reappearing over the loupe.
final class BackgroundCursorTests: XCTestCase {
    func test_setAllowed_findsTheWindowServerFunctions_andTheySucceed() {
        XCTAssertTrue(BackgroundCursor.setAllowed(true))
        XCTAssertTrue(BackgroundCursor.setAllowed(false))
    }
}
