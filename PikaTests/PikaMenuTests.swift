import AppKit
@testable import Pika
import XCTest

/// The status item's right-click menu, built from `PikaMenu.entries`: its groups laid out flat,
/// window-only items left out, and shortcuts taken from `PikaShortcuts`.
final class PikaMenuTests: XCTestCase {
    private final class Delegate: NSObject, NSMenuDelegate {}

    private let delegate = Delegate()
    private var menu: NSMenu { PikaMenu.statusMenu(delegate: delegate) }

    func test_statusMenu_hasNoLeadingTrailingOrDoubledSeparators() {
        let items = menu.items
        XCTAssertFalse(items.isEmpty)
        XCTAssertFalse(items.first?.isSeparatorItem ?? true, "starts with a separator")
        XCTAssertFalse(items.last?.isSeparatorItem ?? true, "ends with a separator")
        for (previous, item) in zip(items, items.dropFirst()) {
            XCTAssertFalse(previous.isSeparatorItem && item.isSeparatorItem, "two separators in a row")
        }
    }

    func test_statusMenu_leavesOutTheWindowsOwnItems() {
        let actions = menu.items.compactMap(\.action)
        XCTAssertFalse(actions.contains(#selector(AppDelegate.triggerUndo)))
        XCTAssertFalse(actions.contains(#selector(AppDelegate.triggerRedo)))
        XCTAssertFalse(menu.items.contains { $0.title == PikaText.textViewPalettes })
    }

    func test_statusMenu_laysGroupsOutFlatWithTheirLongNames() {
        let titles = menu.items.map(\.title)
        XCTAssertTrue(titles.contains(PikaText.textPasteForeground))
        XCTAssertTrue(titles.contains(PikaText.textCopyBackground))
        XCTAssertFalse(menu.items.contains(where: \.hasSubmenu), "a group was left as a submenu")
    }

    func test_statusMenu_usesTheShortcutsFromPikaShortcuts() {
        for item in menu.items where !item.isSeparatorItem {
            guard let action = item.action,
                  let shortcut = PikaShortcuts.all.first(where: { $0.action == action })
            else {
                XCTAssertEqual(item.keyEquivalent, "", "\(item.title) has a key with no matching shortcut")
                continue
            }
            XCTAssertEqual(item.keyEquivalent, shortcut.character, item.title)
            XCTAssertEqual(item.keyEquivalentModifierMask, shortcut.modifiers, item.title)
        }
    }
}
