@testable import Pika
import XCTest

final class WCAGComplianceTests: XCTestCase {
    // White on black — contrast 21:1 — all levels pass
    func test_whiteOnBlack_allLevelPass() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let black = NSColor(r: 0, g: 0, b: 0)
        let result = white.WCAGCompliance(with: black)
        XCTAssertTrue(result.ratio30)
        XCTAssertTrue(result.ratio45)
        XCTAssertTrue(result.ratio70)
    }

    // Same color — contrast 1:1 — all levels fail
    func test_sameColor_allLevelsFail() {
        let gray = NSColor(r: 128, g: 128, b: 128)
        let result = gray.WCAGCompliance(with: gray)
        XCTAssertFalse(result.ratio30)
        XCTAssertFalse(result.ratio45)
        XCTAssertFalse(result.ratio70)
    }

    // Contrast ≥ 3:1 but < 4.5:1 — only ratio30 passes
    func test_lowContrast_onlyRatio30Passes() {
        // Dark gray on light gray: empirically ~3.95:1
        let lightGray = NSColor(r: 200, g: 200, b: 200)
        let darkGray = NSColor(r: 90, g: 90, b: 90)
        let result = lightGray.WCAGCompliance(with: darkGray)
        XCTAssertTrue(result.ratio30)
        XCTAssertFalse(result.ratio45)
        XCTAssertFalse(result.ratio70)
    }

    // Contrast ≥ 4.5:1 but < 7:1 — ratio30 and ratio45 pass
    func test_mediumContrast_ratio30And45Pass() {
        // rgb(120,120,120) on black: luminance ≈ 0.188 → contrast ≈ 4.76:1
        let background = NSColor(r: 120, g: 120, b: 120)
        let text = NSColor(r: 0, g: 0, b: 0)
        let result = background.WCAGCompliance(with: text)
        XCTAssertTrue(result.ratio30)
        XCTAssertTrue(result.ratio45)
        XCTAssertFalse(result.ratio70)
    }

    // toWCAGCompliance is an alias — results should be identical
    func test_toWCAGCompliance_equivalentToWCAGCompliance() {
        let white = NSColor(r: 1, g: 1, b: 1)
        let black = NSColor(r: 0, g: 0, b: 0)
        let direct = white.WCAGCompliance(with: black)
        let alias = white.toWCAGCompliance(with: black)
        XCTAssertEqual(direct.ratio30, alias.ratio30)
        XCTAssertEqual(direct.ratio45, alias.ratio45)
        XCTAssertEqual(direct.ratio70, alias.ratio70)
    }

    // isSymmetric — contrast is the same regardless of order
    func test_WCAGCompliance_isSymmetric() {
        let colorA = NSColor(r: 50, g: 100, b: 200)
        let colorB = NSColor(r: 220, g: 220, b: 220)
        let colorAB = colorA.WCAGCompliance(with: colorB)
        let colorBA = colorB.WCAGCompliance(with: colorA)
        XCTAssertEqual(colorAB.ratio30, colorBA.ratio30)
        XCTAssertEqual(colorAB.ratio45, colorBA.ratio45)
        XCTAssertEqual(colorAB.ratio70, colorBA.ratio70)
    }

    // Ratio levels are cumulative — ratio70 can't pass without ratio45
    func test_WCAGCompliance_levelOrder_isCumulative() {
        let colors: [NSColor] = [
            NSColor(r: 0, g: 0, b: 0),
            NSColor(r: 50, g: 50, b: 50),
            NSColor(r: 128, g: 128, b: 128),
            NSColor(r: 200, g: 200, b: 200),
            NSColor(r: 255, g: 255, b: 255),
        ]
        let white = NSColor(r: 255, g: 255, b: 255)
        for color in colors {
            let result = color.WCAGCompliance(with: white)
            if result.ratio70 { XCTAssertTrue(result.ratio45) }
            if result.ratio45 { XCTAssertTrue(result.ratio30) }
        }
    }
}
