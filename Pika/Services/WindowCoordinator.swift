import Cocoa
import Defaults
import SwiftUI

/// Owns all secondary window lifecycle — creation, presentation, and visibility.
/// The primary Pika window is created here and exposed for `applicationShouldHandleReopen`.
class WindowCoordinator: NSObject {
    weak var eyedroppers: Eyedroppers?

    private(set) var pikaWindow: NSWindow!
    private var borderWindow: NSWindow?
    /// The border window extends this far beyond the main window frame so its outline can
    /// be drawn out on the window's visible glass edge (which sits just past the frame).
    private let borderPad: CGFloat = 6.0
    private var splashWindow: NSWindow!
    private var aboutWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var preferencesWindow: NSWindow?

    private var pikaTouchBarController: PikaTouchBarController!
    private var splashTouchBarController: SplashTouchBarController?
    private var aboutTouchBarController: SplashTouchBarController?

    private let notificationCenter = NotificationCenter.default

    func setupMainWindow(eyedroppers: Eyedroppers) {
        self.eyedroppers = eyedroppers
        pikaWindow = PikaWindow.createPrimaryWindow()
        pikaTouchBarController = PikaTouchBarController(window: pikaWindow)
        // `PikaTouchBarController` is an `NSWindowController`, and taking ownership of
        // the window resets its `frameAutosaveName` to the controller's own (empty)
        // `windowFrameAutosaveName`, wiping the name set in `createPrimaryWindow` and
        // silently disabling frame autosave. Assign the name on the controller so it
        // sticks and AppKit persists size/position on move and resize.
        pikaTouchBarController.windowFrameAutosaveName = PikaWindow.primaryWindowAutosaveName

        // The adaptive layout posts this when the user taps "expand to fit"; grow the
        // window just enough to reveal the elements it's currently suppressing.
        notificationCenter.addObserver(
            forName: .expandToFit, object: nil, queue: .main
        ) { [weak self] note in
            guard let self, let size = (note.object as? NSValue)?.sizeValue else { return }
            self.resizeMainWindow(toFitContent: size)
        }

        // Apply the shadow setting and show/hide the companion border to match.
        Defaults.observe(.windowShadow) { [weak self] change in
            guard let self else { return }
            self.pikaWindow.hasShadow = change.newValue.showsShadowAtRest
            self.updateShadowBorder()
        }.tieToLifetime(of: self)

        // Keep the border on the same window level as the main window (which PikaWindow
        // moves between .floating/.normal), so toggling "float on top" doesn't leave the
        // border stranded on a stale level.
        Defaults.observe(.appFloating) { [weak self] change in
            self?.borderWindow?.level = change.newValue == true ? .floating : .normal
        }.tieToLifetime(of: self)

        // Keep the border aligned to the main window and re-attached whenever it shows.
        for name in [NSWindow.didResizeNotification, NSWindow.didMoveNotification] {
            notificationCenter.addObserver(forName: name, object: pikaWindow, queue: .main) {
                [weak self] _ in
                guard let self, let border = self.borderWindow, border.parent != nil else { return }
                border.setFrame(self.borderFrame(), display: true)
            }
        }
        notificationCenter.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: pikaWindow, queue: .main
        ) { [weak self] _ in
            self?.updateShadowBorder()
        }

        updateShadowBorder()
    }

    /// The main window can lose its drop shadow (either via the setting or while picking),
    /// which lets it blend into the desktop. A `.borderless`, click-through child window
    /// laid exactly over it draws a hairline outline (matching the in-window dividers) so
    /// the edge stays defined. Shown only while the window is shadowless.
    func updateShadowBorder() {
        guard pikaWindow != nil else { return }

        guard !pikaWindow.hasShadow else {
            if let border = borderWindow {
                pikaWindow.removeChildWindow(border)
                border.orderOut(nil)
            }
            return
        }

        let border = borderWindow ?? makeBorderWindow()
        borderWindow = border
        border.setFrame(borderFrame(), display: true)
        if border.parent == nil {
            pikaWindow.addChildWindow(border, ordered: .above)
        }
        border.level = pikaWindow.level
        if let borderView = border.contentView as? ShadowBorderView {
            // Sit the stroke on the main window's frame edge (which lines up with the
            // visible glass edge), and match the window's rounded-corner radius.
            borderView.strokeInset = borderPad
            borderView.cornerRadius = 20
        }
        border.orderFront(nil)
        border.contentView?.needsDisplay = true
    }

    /// The border window frame — the main window's frame grown by `borderPad` on all sides.
    private func borderFrame() -> NSRect {
        pikaWindow.frame.insetBy(dx: -borderPad, dy: -borderPad)
    }

    private func makeBorderWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: borderFrame(),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = pikaWindow.level
        window.contentView = ShadowBorderView()
        return window
    }

    /// Grows the main window so its content area is at least `contentSize`, keeping the
    /// top-left corner fixed (the natural anchor for a window being enlarged). Clamped to
    /// the window's own min/max so it never fights the resize limits.
    private func resizeMainWindow(toFitContent contentSize: NSSize) {
        // `sizingOptions` mirrors the SwiftUI frame's min/max onto the window's content
        // size limits, so clamp the request to those before converting to a window frame.
        let minContent = pikaWindow.contentMinSize
        let maxContent = pikaWindow.contentMaxSize
        let targetContentWidth = min(max(contentSize.width, minContent.width), maxContent.width)
        let targetContentHeight = min(max(contentSize.height, minContent.height), maxContent.height)

        // Chrome (titlebar + toolbar) sits outside the SwiftUI content, so add the live
        // inset to turn a content height into a window height. Width has no side chrome.
        let chromeHeight = pikaWindow.frame.height - pikaWindow.contentLayoutRect.height

        var frame = pikaWindow.frame
        // Only ever grow — never shrink an axis that already has room.
        let newWidth = max(frame.width, targetContentWidth)
        let newHeight = max(frame.height, targetContentHeight + chromeHeight)
        let top = frame.maxY
        frame.size = NSSize(width: newWidth, height: newHeight)
        frame.origin.y = top - newHeight
        pikaWindow.setFrame(frame, display: true, animate: true)
    }

    /// Mounts the SwiftUI content tree on the main window. Call only when the active mode
    /// uses the floating window so the tree's notification listeners aren't running
    /// alongside the popover's copy.
    func installMainWindowContent() {
        guard let eyedroppers = eyedroppers else { return }
        let contentView = ContentView()
            .environmentObject(eyedroppers)
            // Floor is well below the "everything visible" height: ContentView sheds
            // elements adaptively as it shrinks (see PikaAdaptiveHeight), so the window
            // can get compact again. Ideal stays at the comfortable first-launch size.
            .frame(
                minWidth: 360,
                idealWidth: 480,
                maxWidth: 650,
                minHeight: 160,
                idealHeight: 280,
                maxHeight: 400,
                alignment: .center
            )
        let hostingView = NSHostingView(rootView: contentView)
        // Apply the SwiftUI min/max as the window's resize limits, but omit
        // `.intrinsicContentSize` so the hosting view doesn't snap the window back
        // to its ideal size on install — that would clobber the frame restored from
        // user defaults each launch and defeat window persistence.
        hostingView.sizingOptions = [.minSize, .maxSize]
        pikaWindow.contentView = hostingView
    }

    func removeMainWindowContent() {
        pikaWindow.contentView = nil
    }

    /// Drops or restores the main window's drop shadow around an active pick.
    /// Only takes effect for `.hiddenWhilePicking`; the other modes keep their
    /// resting shadow, which is owned by `PikaWindow`.
    func setPickingShadowSuppressed(_ suppressed: Bool) {
        guard Defaults[.windowShadow] == .hiddenWhilePicking else { return }
        pikaWindow.hasShadow = !suppressed
        updateShadowBorder()
    }

    func startMainWindow() {
        if !pikaWindow.isVisible {
            pikaWindow.fadeIn(nil)
        }
        updateShadowBorder()
        Defaults[.viewedSplash] = true
    }

    func showMainWindow() {
        pikaWindow.makeKeyAndOrderFront(nil)
        updateShadowBorder()
    }

    func hideMainWindow() {
        pikaWindow.orderOut(nil)
    }

    func closeSplashWindow() {
        splashWindow.fadeOut(
            sender: nil, duration: 0.25, closeSelector: .close, completionHandler: startMainWindow
        )
    }

    func togglePopover() {
        if pikaWindow.isVisible {
            hideMainWindow()
        } else {
            showMainWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showPika() {
        if pikaWindow.isVisible {
            pikaWindow.makeKeyAndOrderFront(nil)
        } else {
            pikaWindow.fadeIn(sender: nil, duration: 0.2)
        }
        updateShadowBorder()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePika() {
        hideMainWindow()
    }

    func openAboutWindow() {
        if aboutWindow == nil {
            let view = NSHostingView(rootView: AboutView().ignoresSafeArea())
            aboutWindow = PikaWindow.createSecondaryWindow(
                title: PikaText.textMenuAbout,
                size: NSRect(x: 0, y: 0, width: 400, height: 420),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            aboutWindow?.titlebarAppearsTransparent = true
            aboutWindow?.setFrameAutosaveName("")
            aboutWindow?.contentView = view
        }
        aboutTouchBarController = SplashTouchBarController(window: aboutWindow!)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    func openHelpWindow() {
        if helpWindow == nil {
            let rootView = HelpView()
                .frame(minWidth: 440, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                .ignoresSafeArea()
            let view = NSHostingView(rootView: rootView)
            helpWindow = PikaWindow.createSecondaryWindow(
                title: PikaText.textMenuHelp,
                size: NSRect(x: 0, y: 0, width: 550, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            )
            helpWindow?.titlebarAppearsTransparent = true
            helpWindow?.minSize = NSSize(width: 440, height: 400)
            helpWindow?.contentMinSize = NSSize(width: 440, height: 400)
            helpWindow?.contentView = view
        }
        helpWindow?.makeKeyAndOrderFront(nil)
    }

    func openPreferencesWindow() {
        if preferencesWindow == nil, let eyedroppers {
            let rootView = PreferencesView()
                .frame(minWidth: 580, maxWidth: 580, minHeight: 400, maxHeight: .infinity)
                .ignoresSafeArea()
                .environmentObject(eyedroppers)
            let view = NSHostingView(rootView: rootView)
            preferencesWindow = PikaWindow.createSecondaryWindow(
                title: PikaText.textMenuPreferences,
                size: NSRect(x: 0, y: 0, width: 580, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            )
            preferencesWindow?.minSize = NSSize(width: 580, height: 400)
            preferencesWindow?.maxSize = NSSize(width: 580, height: CGFloat.greatestFiniteMagnitude)
            preferencesWindow?.contentMinSize = NSSize(width: 580, height: 400)
            preferencesWindow?.contentView = view
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        preferencesWindow?.makeFirstResponder(nil)
        notificationCenter.post(name: .triggerPreferences, object: self)
    }

    func openSplashWindow() {
        splashWindow = PikaWindow.createSecondaryWindow(
            title: PikaText.textAppName,
            size: NSRect(x: 0, y: 0, width: 650, height: 380),
            styleMask: [.titled, .fullSizeContentView]
        )
        // `createSecondaryWindow` derives the autosave name from the title, which for
        // the splash ("Pika") collides with the main window's "Pika Window" name and
        // would let the transient, always-centered splash pollute the persisted main
        // window frame. The splash never needs to remember its position, so clear it.
        splashWindow.setFrameAutosaveName("")
        splashWindow.titlebarAppearsTransparent = true
        splashTouchBarController = SplashTouchBarController(window: splashWindow)
        splashWindow.contentView = NSHostingView(rootView: SplashView().ignoresSafeArea())
        splashWindow.fadeIn(nil)
    }
}

/// Draws the main window's hairline outline for the companion border window. Strokes a
/// rounded rect matching the window's corner radius, in a colour that adapts to the
/// current appearance (matching `AdaptiveDivider`).
private final class ShadowBorderView: NSView {
    /// Corner radius of the window's visible edge.
    var cornerRadius: CGFloat = 16.0 { didSet { needsDisplay = true } }
    /// How far the stroke sits inside the view bounds. The view is larger than the main
    /// window frame (see `WindowCoordinator.borderPad`); reducing this pushes the outline
    /// outward to sit on the window's visible glass edge rather than its frame.
    var strokeInset: CGFloat = 4.0 { didSet { needsDisplay = true } }

    override var allowsVibrancy: Bool { false }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_: NSRect) {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let color =
            isDark
                ? NSColor.white.withAlphaComponent(0.14)
                : NSColor.black.withAlphaComponent(0.24)
        let rect = bounds.insetBy(dx: strokeInset, dy: strokeInset)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.lineWidth = 1.0
        color.setStroke()
        path.stroke()
    }
}
