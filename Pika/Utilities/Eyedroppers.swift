import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)
    var hasSetInitialBackground = false
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
    }

    /// Tracks which eyedropper currently owns the shared NSColorPanel.
    /// Used by togglePicker() to know whether to open or close the panel.
    private static var activePickerType: Types?

    let type: Types
    var forceShow = false
    /// Injected from AppDelegate; weak to avoid a retain cycle (AppDelegate owns both).
    weak var colorHistoryManager: ColorHistoryManager?

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

    /// Pass `recordToHistory: false` when setting from a history/palette tap
    /// to avoid re-recording a color the user selected from an existing list.
    func set(_ selectedColor: NSColor, recordToHistory: Bool = true) {
        let previousColor = color
        undoManager?.registerUndo(withTarget: self) { _ in
            self.set(previousColor)
        }

        color = selectedColor.usingColorSpace(Defaults[.colorSpace])!
        if recordToHistory {
            colorHistoryManager?.recordImmediate(color)
        }
    }

    /// Sets a color from a swatch tap (without recording to history) and triggers copy.
    func applyFromSwatch(_ color: NSColor) {
        set(color, recordToHistory: false)
        NSApp.sendAction(type.copySelector, to: nil, from: nil)
    }

    /// Promotes an existing color to the front of the history list.
    func promoteInHistory(hex: String) {
        colorHistoryManager?.moveToFront(hex: hex)
    }

    @objc func colorDidChange(sender: AnyObject) {
        if let picker = sender as? NSColorPanel {
            let previousColor = color
            undoManager?.registerUndo(withTarget: self) { _ in
                self.set(previousColor)
            }

            color = picker.color.usingColorSpace(Defaults[.colorSpace])!
            colorHistoryManager?.recordDebounced(color)
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
        panel.setAction(#selector(colorDidChange))
        panel.isContinuous = true
        Self.activePickerType = type

        // Activate before showing — required in menubar mode where the app
        // runs with .accessory activation policy and orderFrontRegardless()
        // alone cannot bring the panel on screen from a MenuBarExtra popover.
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
    }

    func togglePicker() {
        let panel = NSColorPanel.shared
        if panel.isVisible, Self.activePickerType == type {
            panel.close()
            Self.activePickerType = nil
        } else {
            picker()
        }
    }

    func start() {
        let isMenubarMode = Defaults[.appMode] == .menubar && !Defaults[.openAsWindow]

        if !isMenubarMode, Defaults[.hidePikaWhilePicking] {
            if NSApp.mainWindow?.isVisible == true {
                forceShow = true
            }
            NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        }

        DispatchQueue.main.async {
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

                    if Defaults[.copyColorOnPick] {
                        NSApp.sendAction(self.type.copySelector, to: nil, from: nil)
                    } else if !isMenubarMode {
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
