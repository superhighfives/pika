@testable import Pika
import XCTest

/// Help shows shortcuts as one key cap per modifier plus the key, from the
/// shortcut's string form (e.g. a rebound Pick pair).
final class HelpKeyCapsTests: XCTestCase {
    func test_defaultPickPair() {
        XCTAssertEqual(keyCaps(for: "⌥⌘D"), ["⌥", "⌘", "D"])
    }

    func test_allModifiersAndMultiCharacterKey() {
        XCTAssertEqual(keyCaps(for: "⌃⌥⇧⌘F12"), ["⌃", "⌥", "⇧", "⌘", "F12"])
    }

    func test_keyWithoutModifiers() {
        XCTAssertEqual(keyCaps(for: "X"), ["X"])
    }

    func test_modifiersOnly() {
        XCTAssertEqual(keyCaps(for: "⌘"), ["⌘"])
    }

    func test_empty() {
        XCTAssertEqual(keyCaps(for: ""), [])
    }
}
