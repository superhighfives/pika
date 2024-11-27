import Cocoa

extension NSColor {
    struct WCAG {
        var ratio30: Bool
        var ratio45: Bool
        var ratio70: Bool
    }

    func WCAGCompliance(with color: NSColor) -> (WCAG) {
        // WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1
        // for normal text and 3:1 for large text. WCAG 2.1 requires a
        // contrast ratio of at least 3:1 for graphics and user interface
        // components (such as form input borders). WCAG Level AAA requires
        // a contrast ratio of at least 7:1 for normal text and 4.5:1 for large text.
        let ratio = contrastRatio(with: color)
        let results = WCAG(
            ratio30: ratio >= 3.0,
            ratio45: ratio >= 4.5,
            ratio70: ratio >= 7.0
        )
        return results
    }

    func toWCAGCompliance(with color: NSColor) -> (NSColor.WCAG) {
        WCAGCompliance(with: color)
    }
}
