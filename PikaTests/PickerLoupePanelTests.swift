@testable import Pika
import XCTest

/// The custom picker's click catchers. Clicks on a second display fell through to the apps
/// beneath when a single catcher was stretched across every screen (#302): with "Displays have
/// separate Spaces" on, macOS shows a window on one display only.
final class PickerLoupePanelTests: XCTestCase {
    private let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let right = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
    private let aboveLeft = CGRect(x: -1280, y: 1080, width: 1280, height: 800)

    func test_frames_oneScreen_coversIt() {
        XCTAssertEqual(LoupeClickCatcherPanel.frames(coveringScreens: [primary]), [primary])
    }

    func test_frames_twoScreens_givesOneCatcherPerScreen_notTheirBoundingRect() {
        let frames = LoupeClickCatcherPanel.frames(coveringScreens: [primary, right])
        XCTAssertEqual(frames, [primary, right])
        XCTAssertFalse(frames.contains(primary.union(right)))
    }

    /// The property that matters: no catcher reaches onto a second screen, and every screen
    /// is fully under one — whatever the arrangement (including negative origins).
    func test_frames_neverSpanScreens_andCoverEveryScreen() {
        for screens in [[primary], [primary, right], [primary, aboveLeft], [primary, right, aboveLeft]] {
            let frames = LoupeClickCatcherPanel.frames(coveringScreens: screens)
            for frame in frames {
                let touched = screens.filter { $0.intersects(frame) }
                XCTAssertEqual(touched.count, 1, "\(frame) spans \(touched.count) screens")
            }
            for screen in screens {
                XCTAssertTrue(frames.contains { $0.contains(screen) }, "\(screen) has no catcher")
            }
        }
    }

    func test_frames_ignoresAnEmptyScreenFrame() {
        XCTAssertEqual(LoupeClickCatcherPanel.frames(coveringScreens: [primary, .zero]), [primary])
    }

    func test_cover_setsThePanelToExactlyThatFrame() {
        let panel = LoupeClickCatcherPanel()
        panel.cover(aboveLeft)
        XCTAssertEqual(panel.frame, aboveLeft)
    }
}
