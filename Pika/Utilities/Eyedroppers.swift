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
    @objc @Published public var color: NSColor

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
        sampler.show { selectedColor in
            if let selectedColor = selectedColor {
                self.color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
            }
        }
    }
}
