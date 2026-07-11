import Cocoa
import Defaults
import SwiftUI

class PikaWindow {
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
        // From here on AppKit keeps the frame in sync with user defaults as the
        // user moves or resizes the window.
        let autosaveName = NSWindow.FrameAutosaveName("Pika Window")
        let didRestoreFrame = window.setFrameUsingName(autosaveName)
        window.setFrameAutosaveName(autosaveName)
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
