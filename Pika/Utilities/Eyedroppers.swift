import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)

    func toText() -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        return """
        Foreground: \(foreground.color.toFormat(format: colorFormat))
        Background: \(background.color.toFormat(format: colorFormat))
        The contrast ratio is: \(colorContrastRatio):1
        \(colorWCAGCompliance.ratio30 ? "Passed" : "Failed") at Level AA
        \(colorWCAGCompliance.ratio45 ? "Passed" : "Failed") at Level AA / Level AAA Large
        \(colorWCAGCompliance.ratio70 ? "Passed" : "Failed") at Level AAA
        """
    }

    func toJSON() -> String {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        return """
        {
          "colors": {
            "foreground": "\(foreground.color.toFormat(format: colorFormat))",
            "background": "\(background.color.toFormat(format: colorFormat))"
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

class Eyedropper: ObservableObject {
    enum Types: String {
        case foreground
        case background
    }

    let type: Types
    var forceShow = false

    @objc @Published public var color: NSColor

    init(type: Types, color: NSColor) {
        self.type = type
        self.color = color

        Defaults.observe(.colorSpace) { change in
            self.color = self.color.usingColorSpace(change.newValue)!
        }.tieToLifetime(of: self)
    }

    func start() {
        if Defaults[.hidePikaWhilePicking] {
            if NSApp.mainWindow?.isVisible == true {
                forceShow = true
            }
            NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let sampler = NSColorSampler()
            sampler.show { selectedColor in

                if let selectedColor = selectedColor {
                    self.color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
                    NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                } else if self.forceShow {
                    self.forceShow = false
                    NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                }
            }
        }
    }
}
