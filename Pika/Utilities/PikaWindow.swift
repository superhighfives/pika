import Cocoa
import Defaults
import SwiftUI

class PikaWindow {
    static func createPrimaryWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 150),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.title = PikaText.textAppName
        window.level = Defaults[.appFloating] ? .floating : .normal
        window.isMovableByWindowBackground = true
        window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isEnabled = false
        window.titlebarAppearsTransparent = true

        Defaults.observe(.appFloating) { change in
            window.level = change.newValue == true ? .floating : .normal
        }.tieToLifetime(of: self)

        // Set up toolbar
        window.toolbar = NSToolbar()
        if #available(OSX 11.0, *) {
            window.toolbarStyle = .unifiedCompact
        } else {
            window.toolbar!.showsBaselineSeparator = false
            window.titleVisibility = .hidden
        }
        let toolbarButtons = NSHostingView(rootView: NavigationMenu())
        toolbarButtons.frame.size = toolbarButtons.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = toolbarButtons
        titlebarAccessory.layoutAttribute = .trailing
        window.addTitlebarAccessoryViewController(titlebarAccessory)

        // Frame and content set up
        window.setFrameAutosaveName("Pika Window")
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
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .normal
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false

        return window
    }
}
