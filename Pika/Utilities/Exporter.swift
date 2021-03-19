import Foundation

class Exporter {
    static func toText(_ foreground: Eyedropper, _ background: Eyedropper) -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        let foregroundHex = foreground.color.toFormat(format: ColorFormat.hex)
        let foregroundRgb = foreground.color.toFormat(format: ColorFormat.rgb)
        let foregroundHsb = foreground.color.toFormat(format: ColorFormat.hsb)
        let foregroundHsl = foreground.color.toFormat(format: ColorFormat.hsl)

        let backgroundHex = background.color.toFormat(format: ColorFormat.hex)
        let backgroundRgb = background.color.toFormat(format: ColorFormat.rgb)
        let backgroundHsb = background.color.toFormat(format: ColorFormat.hsb)
        let backgroundHsl = background.color.toFormat(format: ColorFormat.hsl)

        // swiftlint:disable line_length
        return """
        \(NSLocalizedString("color.foreground", comment: "Foreground")): \(foregroundHex) / \(foregroundRgb) / \(foregroundHsb) / \(foregroundHsl)
        \(NSLocalizedString("color.background", comment: "Background")): \(backgroundHex) / \(backgroundRgb) / \(backgroundHsb) / \(backgroundHsl)
        \(NSLocalizedString("color.ratio", comment: "Contrast Ratio")): \(colorContrastRatio):1
        WCAG AA: \(colorWCAGCompliance.ratio30 ? "Pass" : "Fail")
        WCAG AA / AAA Large: \(colorWCAGCompliance.ratio45 ? "Pass" : "Fail")
        WCAG AAA: \(colorWCAGCompliance.ratio70 ? "Pass" : "Fail")
        """
        // swiftlint:enable  line_length
    }

    static func toJSON(_ foreground: Eyedropper, _ background: Eyedropper) -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        return """
        {
          "colors": {
            "foreground": {
              "hex": "\(foreground.color.toFormat(format: ColorFormat.hex))",
              "rgb": "\(foreground.color.toFormat(format: ColorFormat.rgb))",
              "hsb": "\(foreground.color.toFormat(format: ColorFormat.hsb))",
              "hsl": "\(foreground.color.toFormat(format: ColorFormat.hsl))",
              "name": "\(foreground.getClosestColor())"
            },
            "background": {
              "hex": "\(background.color.toFormat(format: ColorFormat.hex))",
              "rgb": "\(background.color.toFormat(format: ColorFormat.rgb))",
              "hsb": "\(background.color.toFormat(format: ColorFormat.hsb))",
              "hsl": "\(background.color.toFormat(format: ColorFormat.hsl))",
              "name": "\(background.getClosestColor())"
            }
          },
          "ratio": "\(colorContrastRatio)",
          "wcag": {
            "ratio30": \(colorWCAGCompliance.ratio30),
            "ratio45": \(colorWCAGCompliance.ratio45),
            "ratio70": \(colorWCAGCompliance.ratio70)
          }
        }
        """
    }
}
