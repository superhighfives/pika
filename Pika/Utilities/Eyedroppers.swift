import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)
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
        let sampler = NSColorSampler()
        NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        sampler.show { selectedColor in
            NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
            if let selectedColor = selectedColor {
                self.color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
            }
        }
    }
}
