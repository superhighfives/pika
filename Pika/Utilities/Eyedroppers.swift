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
