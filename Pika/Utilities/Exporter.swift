import Foundation

class Exporter {
    static func toText(foreground: Eyedropper, background: Eyedropper, style: CopyFormat) -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        let foregroundHex = foreground.color.toFormat(format: ColorFormat.hex, style: style)
        let foregroundRgb = foreground.color.toFormat(format: ColorFormat.rgb, style: style)
        let foregroundHsb = foreground.color.toFormat(format: ColorFormat.hsb, style: style)
        let foregroundHsl = foreground.color.toFormat(format: ColorFormat.hsl, style: style)
        let foregroundOpengl = foreground.color.toFormat(format: ColorFormat.opengl, style: style)
        let foregroundOklch = foreground.color.toFormat(format: ColorFormat.oklch, style: style)

        let backgroundHex = background.color.toFormat(format: ColorFormat.hex, style: style)
        let backgroundRgb = background.color.toFormat(format: ColorFormat.rgb, style: style)
        let backgroundHsb = background.color.toFormat(format: ColorFormat.hsb, style: style)
        let backgroundHsl = background.color.toFormat(format: ColorFormat.hsl, style: style)
        let backgroundOpengl = background.color.toFormat(format: ColorFormat.opengl, style: style)
        let backgroundOklch = background.color.toFormat(format: ColorFormat.oklch, style: style)
        let passMessage = PikaText.textColorPass
        let failMessage = PikaText.textColorFail

        // swiftlint:disable line_length
        return """
        \(PikaText.textColorForeground): Hex \(foregroundHex) · RGB \(foregroundRgb) · HSB \(foregroundHsb) · HSL \(foregroundHsl) · OpenGL \(foregroundOpengl) · OKLCH \(foregroundOklch)
        \(PikaText.textColorBackground): Hex \(backgroundHex) · RGB \(backgroundRgb) · HSB \(backgroundHsb) · HSL \(backgroundHsl) · OpenGL \(backgroundOpengl) · OKLCH \(backgroundOklch)
        \(PikaText.textColorRatio): \(colorContrastRatio):1
        \(PikaText.textColorWCAG): AA Large (\(colorWCAGCompliance.ratio30 ? passMessage : failMessage)) · AA / AAA Large (\(colorWCAGCompliance.ratio45 ? passMessage : failMessage)) · AAA (\(colorWCAGCompliance.ratio70 ? passMessage : failMessage)) · Non-text (\(colorWCAGCompliance.ratio30 ? passMessage : failMessage))
        """
        // swiftlint:enable  line_length
    }

    static func toJSON(foreground: Eyedropper, background: Eyedropper, style: CopyFormat) -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        return """
        {
          "colors": {
            "foreground": {
              "hex": "\(foreground.color.toFormat(format: ColorFormat.hex, style: style))",
              "rgb": "\(foreground.color.toFormat(format: ColorFormat.rgb, style: style))",
              "hsb": "\(foreground.color.toFormat(format: ColorFormat.hsb, style: style))",
              "hsl": "\(foreground.color.toFormat(format: ColorFormat.hsl, style: style))",
              "opengl": "\(foreground.color.toFormat(format: ColorFormat.opengl, style: style))",
              "oklch": "\(foreground.color.toFormat(format: ColorFormat.oklch, style: style))",
              "name": "\(foreground.getClosestColor())"
            },
            "background": {
              "hex": "\(background.color.toFormat(format: ColorFormat.hex, style: style))",
              "rgb": "\(background.color.toFormat(format: ColorFormat.rgb, style: style))",
              "hsb": "\(background.color.toFormat(format: ColorFormat.hsb, style: style))",
              "hsl": "\(background.color.toFormat(format: ColorFormat.hsl, style: style))",
              "opengl": "\(background.color.toFormat(format: ColorFormat.opengl, style: style))",
              "oklch": "\(background.color.toFormat(format: ColorFormat.oklch, style: style))",
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
