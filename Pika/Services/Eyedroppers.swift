import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)

    func recordHistory() {
        let fgHex = foreground.color.toHexString()
        let bgHex = background.color.toHexString()

        let history = Defaults[.colorHistory]
        if let last = history.first, last.foregroundHex == fgHex, last.backgroundHex == bgHex {
            return
        }

        let pair = ColorPair(id: UUID(), foregroundHex: fgHex, backgroundHex: bgHex, date: Date())
        var updated = [pair] + history
        if updated.count > ColorPair.maxHistory {
            updated = Array(updated.prefix(ColorPair.maxHistory))
        }
        Defaults[.colorHistory] = updated
    }
}

class Eyedropper: ObservableObject {
    enum Types: String, CustomStringConvertible {
        case foreground
        case background

        var description: String {
            switch self {
            case .foreground: return PikaText.textColorForeground
            case .background: return PikaText.textColorBackground
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

        var systemPickerSelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerSystemPickerForeground)
            case .background: return #selector(AppDelegate.triggerSystemPickerBackground)
            }
        }

        var pickNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerPickForeground
            case .background: return .triggerPickBackground
            }
        }

        var copyNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerCopyForeground
            case .background: return .triggerCopyBackground
            }
        }

        var systemPickerNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerSystemPickerForeground
            case .background: return .triggerSystemPickerBackground
            }
        }
    }

    let type: Types
    var forceShow = false

    let colorNames: [ColorName] = loadColors()!
    var closestVector: ClosestVector!

    @objc @Published public var color: NSColor

    var undoManager: UndoManager?
    private var overlayWindow = ColorPickOverlayWindow()

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

    func set(_ selectedColor: NSColor) {
        let previousColor = color
        undoManager?.registerUndo(withTarget: self) { _ in
            self.set(previousColor)
        }

        color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
    }

    @objc func colorDidChange(sender: AnyObject) {
        if let picker = sender as? NSColorPanel {
            let previousColor = color
            undoManager?.registerUndo(withTarget: self) { _ in
                self.set(previousColor)
            }

            color = picker.color.usingColorSpace(Defaults[.colorSpace])!
        }
    }

    func picker() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.title = "\(type.rawValue.capitalized)"
        panel.titleVisibility = .visible
        panel.setTarget(self)
        panel.color = color
        panel.mode = .RGB
        panel.colorSpace = Defaults[.colorSpace]
        panel.orderFrontRegardless()
        panel.setAction(#selector(colorDidChange))
        panel.isContinuous = true
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
                    if Defaults[.showColorOverlay] {
                        let colorText = selectedColor.toFormat(
                            format: Defaults[.colorFormat], style: Defaults[.copyFormat]
                        )
                        let cursorPosition = NSEvent.mouseLocation
                        self.overlayWindow.show(
                            colorText: colorText,
                            pickedColor: selectedColor,
                            nearCursor: cursorPosition,
                            duration: Defaults[.colorOverlayDuration]
                        )
                    }

                    self.set(selectedColor)

                    NotificationCenter.default.post(name: .colorPicked, object: nil)

                    if Defaults[.copyColorOnPick] {
                        NSApp.sendAction(self.type.copySelector, to: nil, from: nil)
                    } else {
                        NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                    }
                }

                if self.forceShow {
                    self.forceShow = false
                    NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                }

                let panel = NSColorPanel.shared
                if panel.isVisible {
                    self.picker()
                }
            }
        }
    }
}
