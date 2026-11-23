import AppKit
@testable import Pika
import XCTest

/// The toolbar's colour space label: shortened when the toolbar is short of room, cut to fit with
/// an ellipsis when it still won't, and never wider than it's given.
final class ToolbarSpaceTests: XCTestCase {
    private let aces = NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.acescgLinear)!)!

    func testCommonSpacesKeepTheirNames() {
        XCTAssertEqual(ToolbarSpace.spaceLabel(for: .space(.sRGB), compact: false), "sRGB")
        XCTAssertEqual(ToolbarSpace.spaceLabel(for: .space(.sRGB), compact: true), "sRGB")
        XCTAssertEqual(ToolbarSpace.spaceLabel(for: .space(.displayP3), compact: false), "Display P3")
    }

    func testDisplayP3ShortensToP3() {
        XCTAssertEqual(ToolbarSpace.spaceLabel(for: .space(.displayP3), compact: true), "P3")
    }

    func testLongNamesAreCappedWithAnEllipsis() {
        let full = ToolbarSpace.spaceLabel(for: .space(aces), compact: false)
        let short = ToolbarSpace.spaceLabel(for: .space(aces), compact: true)
        XCTAssertTrue(full.hasSuffix("…"))
        XCTAssertLessThanOrEqual(ToolbarSpace.width(full), 110)
        XCTAssertLessThanOrEqual(ToolbarSpace.width(short), 44)
        XCTAssertTrue((aces.localizedName ?? "").hasPrefix(String(short.dropLast())))
    }

    func testFullNameWhenNotTruncating() {
        XCTAssertEqual(ToolbarSpace.spaceLabel(for: .space(aces), compact: true, truncates: false), aces.localizedName)
    }

    func testLimitCutsEvenShortLabels() {
        for limit: CGFloat in [40, 20, 12] {
            let label = ToolbarSpace.spaceLabel(for: .space(.displayP3), compact: false, limit: limit)
            XCTAssertLessThanOrEqual(ToolbarSpace.width(label), max(limit, ToolbarSpace.width("…")), "limit \(limit)")
        }
    }

    func testNoRoomLeavesTheEllipsis() {
        XCTAssertEqual(ToolbarSpace.truncated("Display P3", to: 0), "…")
    }

    func testTextThatFitsIsUnchanged() {
        XCTAssertEqual(ToolbarSpace.truncated("sRGB", to: 200), "sRGB")
    }
}
