import Cocoa
import Defaults
import SwiftUI

class PikaWindow {
    /// Autosave name for the primary window's frame. Shared so the value set here and
    /// re-asserted on the window's `NSWindowController` (in `WindowCoordinator`) can
    /// never drift apart — a mismatch would silently break restore/autosave.
    static let primaryWindowAutosaveName = NSWindow.FrameAutosaveName("Pika Window")

    static func createPrimaryWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 280),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = PikaText.textAppName
        window.titleVisibility = .hidden
        window.level = Defaults[.appFloating] ? .floating : .normal
        window.isMovableByWindowBackground = true
        window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isEnabled = false
        window.titlebarAppearsTransparent = true

        // The window's drop shadow can bleed onto pixels beneath its edge and skew
        // colour readings taken nearby. Honour the user's shadow preference; the
        // `.hiddenWhilePicking` case keeps the resting shadow and is dropped mid-pick
        // by `Eyedropper.start`. Setting *changes* (and the companion border shown while
        // shadowless) are handled in `WindowCoordinator`.
        window.hasShadow = Defaults[.windowShadow].showsShadowAtRest

        Defaults.observe(.appFloating) { change in
            window.level = change.newValue == true ? .floating : .normal
        }.tieToLifetime(of: self)

        // Set up toolbar
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact

        let toolbarButtons = NSHostingView(rootView: NavigationMenu())
        toolbarButtons.frame.size = toolbarButtons.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = toolbarButtons
        titlebarAccessory.layoutAttribute = .trailing
        window.addTitlebarAccessoryViewController(titlebarAccessory)

        // Restore the previously saved frame so size and position survive quitting
        // and reopening. `setFrameAutosaveName` alone does not reliably re-apply a
        // saved frame, so restore it explicitly and only center on first launch.
        // Note: the autosave name set here is re-asserted on the window's
        // `NSWindowController` (see `WindowCoordinator.setupMainWindow`), because
        // taking ownership of the window otherwise clears it and disables autosave.
        let didRestoreFrame = window.setFrameUsingName(primaryWindowAutosaveName)
        window.setFrameAutosaveName(primaryWindowAutosaveName)
        if !didRestoreFrame {
            window.center()
        }

        return window
    }

    static func createSecondaryWindow(
        title: String,
        size: NSRect,
        styleMask: NSWindow.StyleMask,
        maxHeight _: Int? = nil
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: size,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        if #available(macOS 26, *) {
            window.titleVisibility = .visible
        } else {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }

        window.title = title
        window.level = (Defaults[.appFloating] ? .floating : .normal) + 1
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false

        return window
    }
}
