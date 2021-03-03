import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)

    func toText() -> String {
        """
        Foreground: #XXXXXX
        Background: #XXXXXX
        The contrast ratio is: X:1
        Large text passed at Level AA
        Text passed at Level AA / Level AAA Large
        Text failed at Level AAA
        """
    }

    func toJSON() -> String {
        """
        {
          "colors": {
            "foreground": "#XXXXXX",
            "background": "#XXXXXX"
          },
          "ratio": "XYZ",
          "wcag": {
            "ratio30": true,
            "ratio45": true,
            "ratio70": true
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
            NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let sampler = NSColorSampler()
            sampler.show { selectedColor in
                if Defaults[.hidePikaWhilePicking] {
                    NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                }

                if let selectedColor = selectedColor {
                    self.color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
                }
            }
        }
    }
}
