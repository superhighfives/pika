import Defaults
@testable import Pika
import XCTest

/// Clearing history, and deleting the last entry left.
final class EyedroppersHistoryTests: XCTestCase {
    private static let keys = ["palettes", "activePaletteIndex", "undoStack", "redoStack", "colorSpace"]
    private var saved: [Any?] = []

    override func setUp() {
        super.setUp()
        // Exactly as before afterwards, including absent: the test host shares prefs with any
        // installed Pika.
        let domain = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        saved = Self.keys.map { domain?[$0] }
        Defaults[.colorSpace] = .sRGB
        Defaults[.palettes] = [Palette(id: UUID(), name: nil, pairs: [], createdAt: Date())]
        Defaults[.activePaletteIndex] = 0
        Defaults[.undoStack] = []
        Defaults[.redoStack] = []
    }

    override func tearDown() {
        for (key, value) in zip(Self.keys, saved) {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    /// History is the first palette.
    private var history: [ColorPair] { Defaults[.palettes].first?.pairs ?? [] }

    private func color(_ hex: String) throws -> NSColor {
        try XCTUnwrap(NSColor.fromHex(hex, in: .sRGB))
    }

    func test_clearHistory_keepsTheCurrentPair() throws {
        let eyedroppers = Eyedroppers()
        eyedroppers.foreground.color = try color("#ff8800")
        eyedroppers.background.color = try color("#0e1829")
        eyedroppers.recordHistory()
        eyedroppers.foreground.color = try color("#3a7bd5")
        eyedroppers.recordHistory()

        eyedroppers.clearHistory()

        XCTAssertEqual(eyedroppers.foreground.color.toHexString(), "#3a7bd5")
        XCTAssertEqual(eyedroppers.background.color.toHexString(), "#0e1829")
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.foregroundColor.toHexString(), "#3a7bd5")
        XCTAssertEqual(eyedroppers.activeHistoryID, history.first?.id)
    }

    func test_deletingTheLastEntry_startsAFreshPair() throws {
        let eyedroppers = Eyedroppers()
        eyedroppers.foreground.color = try color("#ff8800")
        eyedroppers.background.color = try color("#0e1829")
        eyedroppers.recordHistory()
        XCTAssertEqual(history.count, 1)

        eyedroppers.deleteCurrentHistoryEntry()

        XCTAssertEqual(eyedroppers.background.color.toHexString(), "#000000")
        XCTAssertTrue(PikaConstants.initialColors.map { $0.toHexString() }
            .contains(eyedroppers.foreground.color.toHexString()))
        XCTAssertEqual(history.count, 1)
    }
}
