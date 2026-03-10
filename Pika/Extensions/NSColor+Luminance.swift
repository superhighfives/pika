import Cocoa

extension NSColor {
    func clip<T: Comparable>(_ v: T, _ minimum: T, _ maximum: T) -> T {
        max(min(v, maximum), minimum)
    }

    var luminance: CGFloat {
        let rgba = toRGBAComponents(in: .extendedSRGB)

        func lumHelper(c: CGFloat) -> CGFloat {
            (c < 0.03928) ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }

        let result = 0.2126 * lumHelper(c: rgba.r) + 0.7152 * lumHelper(c: rgba.g) + 0.0722 * lumHelper(c: rgba.b)
        return max(.zero, result)
    }

    func contrastRatio(with color: NSColor) -> CGFloat {
        let L1 = luminance
        let L2 = color.luminance

        if L1 < L2 {
            return (L2 + 0.05) / (L1 + 0.05)
        } else {
            return (L1 + 0.05) / (L2 + 0.05)
        }
    }

    func toContrastRatioString(with color: NSColor) -> String {
        Double(round(100 * contrastRatio(with: color)) / 100).description as String
    }
}
