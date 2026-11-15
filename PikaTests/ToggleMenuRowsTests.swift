import AppKit
@testable import Pika
import XCTest

/// The View menu's keys while it's open: the arrows move the highlight, a row's key toggles it,
/// and Return and Space toggle the highlighted row.
final class ToggleMenuRowsTests: XCTestCase {
    private var rows: ToggleMenuRows!
    private var views: [ToggleMenuRow] = []
    private var toggled: [String] = []

    override func setUp() {
        super.setUp()
        rows = ToggleMenuRows()
        toggled = []
        views = ["C", "H", "P"].map { key in
            ToggleMenuRow(title: key, key: key, rows: rows, isOn: { false }) { [unowned self] in
                toggled.append(key)
            }
        }
    }

    func test_down_startsAtTheTopAndWraps() {
        XCTAssertTrue(rows.handle(MenuKey(.down)))
        XCTAssertTrue(rows.highlighted === views[0])
        _ = rows.handle(MenuKey(.down))
        _ = rows.handle(MenuKey(.down))
        XCTAssertTrue(rows.highlighted === views[2])
        _ = rows.handle(MenuKey(.down))
        XCTAssertTrue(rows.highlighted === views[0])
    }

    func test_up_startsAtTheBottomAndWraps() {
        XCTAssertTrue(rows.handle(MenuKey(.up)))
        XCTAssertTrue(rows.highlighted === views[2])
        rows.highlight(views[0])
        _ = rows.handle(MenuKey(.up))
        XCTAssertTrue(rows.highlighted === views[2])
    }

    func test_rowKey_togglesItsRow() {
        XCTAssertTrue(rows.handle(MenuKey(.character("h"))))
        XCTAssertEqual(toggled, ["H"])
    }

    func test_otherKey_isLeftToTheMenu() {
        XCTAssertFalse(rows.handle(MenuKey(.character("z"))))
        XCTAssertTrue(toggled.isEmpty)
    }

    func test_returnAndSpace_toggleTheHighlightedRow() {
        rows.highlight(views[2])
        XCTAssertTrue(rows.handle(MenuKey(.return)))
        XCTAssertTrue(rows.handle(MenuKey(.space)))
        XCTAssertEqual(toggled, ["P", "P"])
    }

    func test_returnAndSpace_withNothingHighlighted_areLeftToTheMenu() {
        XCTAssertFalse(rows.handle(MenuKey(.return)))
        XCTAssertFalse(rows.handle(MenuKey(.space)))
        XCTAssertTrue(toggled.isEmpty)
    }

    func test_heldKey_togglesOnce_butArrowsRepeat() {
        _ = rows.handle(MenuKey(.character("c")))
        XCTAssertTrue(rows.handle(MenuKey(.character("c"), isRepeat: true)))
        XCTAssertEqual(toggled, ["C"])
        _ = rows.handle(MenuKey(.down))
        _ = rows.handle(MenuKey(.down, isRepeat: true))
        XCTAssertTrue(rows.highlighted === views[1])
    }

    func test_pointerLeavingAnotherRow_keepsTheHighlight() {
        rows.highlight(views[1])
        rows.unhighlight(views[0])
        XCTAssertTrue(rows.highlighted === views[1])
        rows.unhighlight(views[1])
        XCTAssertNil(rows.highlighted)
    }

    func test_modifiedKey_isLeftToTheMenu() throws {
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0, windowNumber: 0,
            context: nil, characters: "c", charactersIgnoringModifiers: "c", isARepeat: false, keyCode: 8
        ))
        XCTAssertNil(MenuKey(event))
        XCTAssertFalse(rows.handle(event))
    }
}
