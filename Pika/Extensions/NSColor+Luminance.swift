import Cocoa

extension NSColor {
    func clip<T: Comparable>(_ val: T, _ minimum: T, _ maximum: T) -> T {
        max(min(val, maximum), minimum)
    }

    var luminance: CGFloat {
        // Clamped sRGB: WCAG is defined over sRGB, and colours are now stored as extended sRGB
        // (Eyedropper), so reading extended components here would score out-of-gamut colours on
        // values outside 0–1 and change their contrast ratios.
        let rgba = toRGBAComponents(in: .sRGB)

        func lumHelper(component: CGFloat) -> CGFloat {
            (component < 0.03928) ? (component / 12.92) : pow((component + 0.055) / 1.055, 2.4)
        }

        let result = 0.2126 * lumHelper(component: rgba.r)
            + 0.7152 * lumHelper(component: rgba.g)
            + 0.0722 * lumHelper(component: rgba.b)
        return max(.zero, result)
    }

    func contrastRatio(with color: NSColor) -> CGFloat {
        let lum1 = luminance
        let lum2 = color.luminance

        if lum1 < lum2 {
            return (lum2 + 0.05) / (lum1 + 0.05)
        } else {
            return (lum1 + 0.05) / (lum2 + 0.05)
        }
    }

    func toContrastRatioString(with color: NSColor) -> String {
        Double(round(100 * contrastRatio(with: color)) / 100).description as String
    }

    func toLocalizedContrastRatioString(with color: NSColor, locale: Locale = .current) -> String {
        let value = round(100 * contrastRatio(with: color)) / 100
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
