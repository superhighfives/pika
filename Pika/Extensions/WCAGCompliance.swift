//
//  WCAGCompliance.swift
//  Pika
//
//  Created by Charlie Gleason on 16/01/2021.
//

import Cocoa

extension NSColor {
    struct WCAG {
        var level2A: Bool
        var level3A: Bool
        var level2ALarge: Bool
        var level3ALarge: Bool
    }

    func WCAGCompliance(with color: NSColor) -> (WCAG) {
        // WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1
        // for normal text and 3:1 for large text. WCAG 2.1 requires a
        // contrast ratio of at least 3:1 for graphics and user interface
        // components (such as form input borders). WCAG Level AAA requires
        // a contrast ratio of at least 7:1 for normal text and 4.5:1 for large text.
        let ratio = contrastRatio(with: color)
        let results = WCAG(
            level2A: ratio >= 4.5,
            level3A: ratio >= 7.0,
            level2ALarge: ratio >= 3.0,
            level3ALarge: ratio >= 4.5
        )
        return results
    }
}
