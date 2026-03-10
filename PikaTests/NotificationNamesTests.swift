@testable import Pika
import XCTest

/// Verifies that every typed Notification.Name constant resolves to its
/// expected raw string value. These tests catch accidental regressions
/// if a constant's raw string changes but a subscriber still listens on
/// the old name.
final class NotificationNamesTests: XCTestCase {
    func test_triggerPickForeground() {
        XCTAssertEqual(Notification.Name.triggerPickForeground.rawValue,
                       PikaConstants.ncTriggerPickForeground)
    }

    func test_triggerPickBackground() {
        XCTAssertEqual(Notification.Name.triggerPickBackground.rawValue,
                       PikaConstants.ncTriggerPickBackground)
    }

    func test_triggerCopyForeground() {
        XCTAssertEqual(Notification.Name.triggerCopyForeground.rawValue,
                       PikaConstants.ncTriggerCopyForeground)
    }

    func test_triggerCopyBackground() {
        XCTAssertEqual(Notification.Name.triggerCopyBackground.rawValue,
                       PikaConstants.ncTriggerCopyBackground)
    }

    func test_triggerCopyText() {
        XCTAssertEqual(Notification.Name.triggerCopyText.rawValue,
                       PikaConstants.ncTriggerCopyText)
    }

    func test_triggerCopyData() {
        XCTAssertEqual(Notification.Name.triggerCopyData.rawValue,
                       PikaConstants.ncTriggerCopyData)
    }

    func test_triggerSystemPickerForeground() {
        XCTAssertEqual(Notification.Name.triggerSystemPickerForeground.rawValue,
                       PikaConstants.ncTriggerSystemPickerForeground)
    }

    func test_triggerSystemPickerBackground() {
        XCTAssertEqual(Notification.Name.triggerSystemPickerBackground.rawValue,
                       PikaConstants.ncTriggerSystemPickerBackground)
    }

    func test_triggerSwap() {
        XCTAssertEqual(Notification.Name.triggerSwap.rawValue,
                       PikaConstants.ncTriggerSwap)
    }

    func test_triggerUndo() {
        XCTAssertEqual(Notification.Name.triggerUndo.rawValue,
                       PikaConstants.ncTriggerUndo)
    }

    func test_triggerRedo() {
        XCTAssertEqual(Notification.Name.triggerRedo.rawValue,
                       PikaConstants.ncTriggerRedo)
    }

    func test_triggerPreferences() {
        XCTAssertEqual(Notification.Name.triggerPreferences.rawValue,
                       PikaConstants.ncTriggerPreferences)
    }

    func test_triggerFormatHex() {
        XCTAssertEqual(Notification.Name.triggerFormatHex.rawValue,
                       PikaConstants.ncTriggerFormatHex)
    }

    func test_triggerFormatRGB() {
        XCTAssertEqual(Notification.Name.triggerFormatRGB.rawValue,
                       PikaConstants.ncTriggerFormatRGB)
    }

    func test_triggerFormatHSB() {
        XCTAssertEqual(Notification.Name.triggerFormatHSB.rawValue,
                       PikaConstants.ncTriggerFormatHSB)
    }

    func test_triggerFormatHSL() {
        XCTAssertEqual(Notification.Name.triggerFormatHSL.rawValue,
                       PikaConstants.ncTriggerFormatHSL)
    }

    func test_triggerFormatOpenGL() {
        XCTAssertEqual(Notification.Name.triggerFormatOpenGL.rawValue,
                       PikaConstants.ncTriggerFormatOpenGL)
    }

    func test_triggerFormatLAB() {
        XCTAssertEqual(Notification.Name.triggerFormatLAB.rawValue,
                       PikaConstants.ncTriggerFormatLAB)
    }

    func test_triggerFormatOKLCH() {
        XCTAssertEqual(Notification.Name.triggerFormatOKLCH.rawValue,
                       PikaConstants.ncTriggerFormatOKLCH)
    }
}
