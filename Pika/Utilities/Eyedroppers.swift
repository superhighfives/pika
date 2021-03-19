import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)
}

class Eyedropper: ObservableObject {
    enum Types: String, CustomStringConvertible {
        case foreground
        case background

        var description: String {
            switch self {
            case .foreground: return NSLocalizedString("color.foreground", comment: "Foreground")
            case .background: return NSLocalizedString("color.background", comment: "Background")
            }
        }

        var copySelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerCopyForeground)
            case .background: return #selector(AppDelegate.triggerCopyBackground)
            }
        }

        var pickSelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerPickForeground)
            case .background: return #selector(AppDelegate.triggerPickBackground)
            }
        }
    }

    let type: Types
    var forceShow = false

    let colorNames: [ColorName] = loadColors()!
    var closestVector: ClosestVector!

    @objc @Published public var color: NSColor

    init(type: Types, color: NSColor) {
        self.type = type
        self.color = color

        // Load colors
        closestVector = ClosestVector(colorNames.map { $0.color.toRGB8BitArray() })

        Defaults.observe(.colorSpace) { change in
            self.color = self.color.usingColorSpace(change.newValue)!
        }.tieToLifetime(of: self)
    }

    func getClosestColor() -> String {
        colorNames[closestVector.compare(color)].name
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
