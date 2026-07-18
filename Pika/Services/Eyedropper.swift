import Defaults
import SwiftUI

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
    var pendingChainCommit = false

    let colorNames: [ColorName] = loadColors()!
    var closestVector: ClosestVector!

    @objc @Published public var color: NSColor

    private var overlayWindow = ColorPickOverlayWindow()

    init(type: Types, color: NSColor) {
        self.type = type
        self.color = color.usingColorSpace(.sRGB) ?? color

        // Load colors
        closestVector = ClosestVector(colorNames.map { $0.color.toRGB8BitArray() })
    }

    func getClosestColor() -> String {
        colorNames[closestVector.compare(color)].name
    }

    func set(_ selectedColor: NSColor) {
        color = selectedColor.usingColorSpace(.sRGB) ?? selectedColor
    }

    @objc func colorDidChange(sender: AnyObject) {
        if let picker = sender as? NSColorPanel {
            guard let srgbColor = picker.color.usingColorSpace(.sRGB) else { return }
            color = srgbColor
            NotificationCenter.default.post(name: .systemColorChanged, object: nil)
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
}

// MARK: - Screen sampling

extension Eyedropper {
    func start(chainContrasting: Bool = false) {
        if Defaults[.hidePikaWhilePicking] {
            if NSApp.mainWindow?.isVisible == true {
                forceShow = true
            }
            NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        }

        // Drop the window's shadow while the sampler is up so it can't tint pixels
        // picked near the window edge. Restored on every terminal pick path below;
        // a chained background pick simply re-suppresses when it starts. The call is
        // a no-op unless the shadow preference is `.hiddenWhilePicking`.
        (NSApp.delegate as? AppDelegate)?.windowCoordinator.setPickingShadowSuppressed(true)

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if Defaults[.appMode].usesPopover {
                NSApp.activate(ignoringOtherApps: true)
            }
            let sampler = NSColorSampler()
            sampler.show { selectedColor in
                if let selectedColor = selectedColor {
                    self.commitPick(selectedColor, chainContrasting: chainContrasting)
                } else if self.pendingChainCommit {
                    self.commitCancelledChain()
                } else {
                    // Fresh pick cancelled: restore the shadow the sampler suppressed.
                    (NSApp.delegate as? AppDelegate)?.windowCoordinator
                        .setPickingShadowSuppressed(false)
                }

                if self.forceShow {
                    self.forceShow = false
                    if !Defaults[.appMode].usesPopover {
                        NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                    }
                }

                let panel = NSColorPanel.shared
                if panel.isVisible {
                    self.picker()
                }
            }
        }
    }

    private func commitPick(_ selectedColor: NSColor, chainContrasting: Bool) {
        let normalizedColor = selectedColor.usingColorSpace(.sRGB) ?? selectedColor

        if Defaults[.showColorOverlay] {
            let colorText = normalizedColor.toFormat(
                format: Defaults[.colorFormat], style: Defaults[.copyFormat]
            )
            let cursorPosition = NSEvent.mouseLocation
            overlayWindow.show(
                colorText: colorText,
                pickedColor: normalizedColor,
                nearCursor: cursorPosition,
                duration: Defaults[.colorOverlayDuration]
            )
        }

        set(normalizedColor)

        if chainContrasting,
           type == .foreground,
           let appDelegate = NSApp.delegate as? AppDelegate
        {
            startChainedBackgroundPick(using: appDelegate)
        } else {
            pendingChainCommit = false
            NotificationCenter.default.post(name: .colorPicked, object: nil)
            finishPick(copySelector: type.copySelector)
        }
    }

    private func startChainedBackgroundPick(using appDelegate: AppDelegate) {
        // Defer committing the foreground pick — we'll record once the
        // background is also picked (or the chained pick is cancelled).
        let background = appDelegate.eyedroppers.background
        background.pendingChainCommit = true
        // Don't bounce Pika back into view between picks: forward the
        // forceShow intent to the background pick instead.
        if forceShow {
            forceShow = false
            background.forceShow = true
        }
        let delay: Double = Defaults[.showColorOverlay] ? 0.4 : 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            background.start()
        }
    }

    private func commitCancelledChain() {
        // Chained background pick was cancelled; commit the foreground change
        // that was deferred so it isn't lost. self.type is .background here, so
        // route copy-on-pick to the foreground selector explicitly.
        pendingChainCommit = false
        NotificationCenter.default.post(name: .colorPicked, object: nil)
        finishPick(copySelector: Eyedropper.Types.foreground.copySelector)
    }

    private func finishPick(copySelector: Selector) {
        if Defaults[.copyColorOnPick] {
            NSApp.sendAction(copySelector, to: nil, from: nil)
        } else if Defaults[.appMode].usesPopover {
            NSApp.sendAction(#selector(AppDelegate.showPopover), to: nil, from: nil)
        } else {
            NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
        }

        // Terminal path for a committed pick (or a cancelled chain): bring the
        // window's shadow back. No-op unless the shadow preference suppressed it.
        (NSApp.delegate as? AppDelegate)?.windowCoordinator.setPickingShadowSuppressed(false)
    }
}
