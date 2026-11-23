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

        // The window's drop shadow can bleed onto pixels beneath its edge and skew colour
        // readings taken nearby. Seed a sensible initial native shadow from the preference;
        // `WindowCoordinator.applyShadowState` takes full ownership immediately after setup
        // (including swapping in the custom, fadeable shadow for `.hiddenWhilePicking`).
        window.hasShadow = Defaults[.windowShadow].showsShadowAtRest

        Defaults.observe(.appFloating) { change in
            window.level = change.newValue == true ? .floating : .normal
        }.tieToLifetime(of: self)

        // Set up toolbar
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact

        let toolbarButtons = FittingHostingView(rootView: NavigationMenu())
        toolbarButtons.frame.size = toolbarButtons.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = toolbarButtons
        titlebarAccessory.layoutAttribute = .trailing
        window.addTitlebarAccessoryViewController(titlebarAccessory)

        // The palettes sidebar's toggle, after the traffic lights.
        let sidebarButton = FittingHostingView(rootView: SidebarToggleButton())
        sidebarButton.frame.size = sidebarButton.fittingSize
        let sidebarAccessory = NSTitlebarAccessoryViewController()
        sidebarAccessory.view = sidebarButton
        sidebarAccessory.layoutAttribute = .leading
        window.addTitlebarAccessoryViewController(sidebarAccessory)

        fitToolbar(toolbarButtons, besides: sidebarButton, in: window)

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

    /// When the whole toolbar won't fit beside the sidebar button, Swap gives way first, then the
    /// colour space's label shortens (`ToolbarSpace`).
    private static func fitToolbar(_ toolbar: FittingHostingView<NavigationMenu>, besides sidebar: NSView, in window: NSWindow) {
        let swapWidth = NSHostingView(rootView: SwapButton()).fittingSize.width + 8
        let updateFit = { [weak window] in
            guard let window else { return }
            let space = ToolbarSpace.shared
            let available = window.frame.width - sidebar.convert(sidebar.bounds, to: nil).maxX - 8
            // The toolbar's width with everything at full size, from its width now.
            let fullLabel = ToolbarSpace.labelWidth(compact: false, limit: nil)
            let full = toolbar.fittingSize.width
                + (space.showsSwap ? 0 : swapWidth)
                - ToolbarSpace.labelWidth(compact: space.compactSpace, limit: space.spaceLimit)
                + fullLabel
            let showsSwap = available >= full
            let compactSpace = !showsSwap && available < full - swapWidth
            // What's left for the space's label once everything else is in.
            let room = available - (full - swapWidth - fullLabel)
            let limit = compactSpace && room < ToolbarSpace.labelWidth(compact: true, limit: nil) ? max(room, 0) : nil
            if space.showsSwap != showsSwap { space.showsSwap = showsSwap }
            if space.compactSpace != compactSpace { space.compactSpace = compactSpace }
            if space.spaceLimit != limit { space.spaceLimit = limit }
        }
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: window, queue: .main
        ) { _ in updateFit() }
        toolbar.onWidthChange = updateFit
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
        // Secondary windows (splash, About, Help, Preferences) track the same
        // level as the main Pika window so they don't get buried behind it when
        // "float on top" is enabled (`appFloating` defaults to true, putting the
        // main window at `.floating`). System dialogs like the Screen Recording
        // permission prompt sit above `.floating` regardless, so this stays below
        // them. They also come to the front when opened via `makeKeyAndOrderFront`.
        window.level = Defaults[.appFloating] ? .floating : .normal
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false

        return window
    }
}

/// A hosting view that keeps its frame at its fitting size. A titlebar accessory takes its view's
/// frame as given, so without this the toolbar kept its launch width and clipped longer labels.
final class FittingHostingView<Content: View>: NSHostingView<Content> {
    /// After the view takes a new width, such as when a menu's label changes.
    var onWidthChange: (() -> Void)?

    override func layout() {
        super.layout()
        // After this layout pass, and width only: the titlebar sets the height.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let width = fittingSize.width
            if frame.width != width {
                setFrameSize(NSSize(width: width, height: frame.height))
                onWidthChange?()
            }
        }
    }
}
