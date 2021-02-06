import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Published var foreground = Eyedropper(
        title: "Foreground", color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(title: "Background", color: NSColor.black)
}

class Eyedropper: ObservableObject {
    var title: String
    @Published public var color: NSColor

    func getUIColor() -> (Color) {
        return (color.luminance < 0.3 ? Color.white : Color.black)
    }

    init(title: String, color: NSColor) {
        self.title = title
        self.color = color

        Defaults.observe(.colorSpace) { change in
            self.color = self.color.usingColorSpace(change.newValue)!
        }.tieToLifetime(of: self)
    }

    func start() {
        let sampler = NSColorSampler()
        NSApp.sendAction(#selector(AppDelegate.fadeOutPika), to: nil, from: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sampler.show { selectedColor in
                NSApp.sendAction(#selector(AppDelegate.fadeInPika), to: nil, from: nil)
                if let selectedColor = selectedColor {
                    self.color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
                }
            }
        }
    }
}
