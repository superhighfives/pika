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

    /// A companion window that renders the main window's drop shadow ourselves, used only
    /// in `.hiddenWhilePicking`. AppKit's native `hasShadow` is a plain on/off flag with no
    /// public opacity control, so a *fade* on pick is impossible with it. This layer-backed
    /// window sits behind the main window (its opaque fill is occluded; only the soft shadow
    /// spills past the edges) and its `shadowOpacity` animates 1↔0 as picking starts/ends.
    private var shadowWindow: NSWindow?
    /// Room around the main frame for the soft shadow to spill without the window clipping it.
    private let shadowPad: CGFloat = 60.0
    /// Radius of the main window's visible rounded corners; the border stroke and the custom
    /// shadow both trace this so they line up with the glass edge.
    private let windowCornerRadius: CGFloat = 20.0
    /// Resting opacity of the custom shadow when the window is focused, tuned to sit close
    /// to the native macOS shadow.
    private let focusedShadowOpacity: Float = 0.30
    /// Resting opacity when the window isn't key — a lighter shadow, mirroring how AppKit
    /// softens a native window's shadow once it loses focus.
    private let unfocusedShadowOpacity: Float = 0.13
    /// The resting opacity for the current focus state (ignores picking suppression).
    private var restingShadowOpacity: Float {
        pikaWindow?.isKeyWindow == true ? focusedShadowOpacity : unfocusedShadowOpacity
    }

    /// Whether an active pick currently wants the shadow suppressed. Drives the fade target.
    private var isPickingSuppressed = false
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

        // Re-apply the whole shadow configuration when the setting changes.
        Defaults.observe(.windowShadow) { [weak self] _ in
            self?.applyShadowState(animated: false)
        }.tieToLifetime(of: self)

        // Keep the companion windows on the same level as the main window (which PikaWindow
        // moves between .floating/.normal), so toggling "float on top" doesn't leave them
        // stranded on a stale level.
        Defaults.observe(.appFloating) { [weak self] change in
            let level: NSWindow.Level = change.newValue == true ? .floating : .normal
            self?.borderWindow?.level = level
            self?.shadowWindow?.level = level
        }.tieToLifetime(of: self)

        // Keep the companion windows aligned to the main window as it resizes and moves.
        for name in [NSWindow.didResizeNotification, NSWindow.didMoveNotification] {
            notificationCenter.addObserver(forName: name, object: pikaWindow, queue: .main) {
                [weak self] _ in
                self?.positionCompanionWindows()
            }
        }
        // Focus changes fade the custom shadow between its focused and unfocused resting
        // strengths (`didBecomeKey` also re-asserts the whole configuration on show).
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            notificationCenter.addObserver(forName: name, object: pikaWindow, queue: .main) {
                [weak self] _ in
                self?.applyShadowState(animated: true)
            }
        }

        applyShadowState(animated: false)
    }

    /// Applies the full shadow configuration for the current setting and picking state.
    /// Each mode owns a coherent trio of decisions — native shadow, the custom (fadeable)
    /// shadow, and the hairline edge border:
    ///   • `.always`  — native drop shadow, no companions.
    ///   • `.never`   — no shadow; the hairline border keeps the (otherwise blending) edge.
    ///   • `.hiddenWhilePicking` — native shadow off, custom shadow drawn instead so it can
    ///     fade to nothing while the sampler is up (and the border fades in to hold the edge).
    /// `animated` is `true` only for the pick transition; setting changes and re-asserts snap.
    func applyShadowState(animated: Bool = false) {
        guard pikaWindow != nil else { return }

        switch Defaults[.windowShadow] {
        case .always:
            setNativeShadow(true)
            teardownCustomShadow()
            setBorderVisible(false, animated: animated)
        case .never:
            setNativeShadow(false)
            teardownCustomShadow()
            setBorderVisible(true, animated: animated)
        case .hiddenWhilePicking:
            // The native shadow can't animate, so we render our own and fade it.
            setNativeShadow(false)
            ensureCustomShadow()
            setCustomShadowOpacity(isPickingSuppressed ? 0 : restingShadowOpacity, animated: animated)
            // The edge only needs the hairline while the shadow is gone; crossfade it in.
            setBorderVisible(isPickingSuppressed, animated: animated)
        }
    }

    private func setNativeShadow(_ hasShadow: Bool) {
        pikaWindow.hasShadow = hasShadow
        // AppKit caches a visible window's drop shadow: flipping `hasShadow` on an
        // already-onscreen window doesn't take effect until it's moved, resized, or
        // reordered. Force the recompute so the change lands immediately.
        pikaWindow.invalidateShadow()
    }

    // MARK: Companion windows (hairline border + custom shadow)

    /// Repositions both companion windows to track the main window's current frame.
    private func positionCompanionWindows() {
        if let border = borderWindow, border.parent != nil {
            border.setFrame(borderFrame(), display: true)
        }
        if let shadow = shadowWindow, shadow.parent != nil {
            shadow.setFrame(shadowFrame(), display: true)
        }
    }

    /// Shows or hides the hairline edge border, fading its alpha when `animated`. Never
    /// creates the border just to hide it.
    private func setBorderVisible(_ visible: Bool, animated: Bool) {
        if !visible, borderWindow == nil { return }
        let border = ensureBorderWindow()
        border.setFrame(borderFrame(), display: true)
        let target: CGFloat = visible ? 1 : 0
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                border.animator().alphaValue = target
            }
        } else {
            border.alphaValue = target
        }
    }

    private func ensureBorderWindow() -> NSWindow {
        if let border = borderWindow {
            if border.parent == nil { pikaWindow.addChildWindow(border, ordered: .above) }
            return border
        }
        let border = makeBorderWindow()
        border.alphaValue = 0
        if let borderView = border.contentView as? ShadowBorderView {
            // Sit the stroke on the main window's frame edge (which lines up with the
            // visible glass edge), and match the window's rounded-corner radius.
            borderView.strokeInset = borderPad
            borderView.cornerRadius = windowCornerRadius
        }
        borderWindow = border
        pikaWindow.addChildWindow(border, ordered: .above)
        border.level = pikaWindow.level
        return border
    }

    private func ensureCustomShadow() {
        let shadow = shadowWindow ?? makeShadowWindow()
        shadowWindow = shadow
        shadow.setFrame(shadowFrame(), display: true)
        if shadow.parent == nil { pikaWindow.addChildWindow(shadow, ordered: .below) }
        shadow.level = pikaWindow.level
    }

    private func teardownCustomShadow() {
        guard let shadow = shadowWindow else { return }
        pikaWindow.removeChildWindow(shadow)
        shadow.orderOut(nil)
        shadowWindow = nil
    }

    private func setCustomShadowOpacity(_ opacity: Float, animated: Bool) {
        (shadowWindow?.contentView as? ShadowCasterView)?.setShadowOpacity(opacity, animated: animated)
    }

    /// The border window frame — the main window's frame grown by `borderPad` on all sides.
    private func borderFrame() -> NSRect {
        pikaWindow.frame.insetBy(dx: -borderPad, dy: -borderPad)
    }

    /// The shadow window frame — the main window's frame grown by `shadowPad` so the soft
    /// shadow has room to spill without the window clipping it.
    private func shadowFrame() -> NSRect {
        pikaWindow.frame.insetBy(dx: -shadowPad, dy: -shadowPad)
    }

    private func makeShadowWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: shadowFrame(),
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
        let caster = ShadowCasterView(frame: shadowFrame())
        caster.pad = shadowPad
        caster.cornerRadius = windowCornerRadius
        caster.restingOpacity = restingShadowOpacity
        window.contentView = caster
        return window
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

    /// Fades the main window's drop shadow out (and the edge border in) around an active
    /// pick, and back when it ends. Only `.hiddenWhilePicking` reacts; the other modes have
    /// no custom shadow to fade, so this is a no-op for them.
    func setPickingShadowSuppressed(_ suppressed: Bool) {
        guard isPickingSuppressed != suppressed else { return }
        isPickingSuppressed = suppressed
        applyShadowState(animated: true)
    }

    func startMainWindow() {
        if !pikaWindow.isVisible {
            pikaWindow.fadeIn(nil)
        }
        applyShadowState()
        Defaults[.viewedSplash] = true
    }

    func showMainWindow() {
        pikaWindow.makeKeyAndOrderFront(nil)
        applyShadowState()
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
        applyShadowState()
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
            size: NSRect(x: 0, y: 0, width: 720, height: 440),
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

/// Casts the main window's drop shadow ourselves so its opacity can animate — AppKit's
/// native `hasShadow` can't. A rounded-rect fill (sized to the main window and occluded by
/// it, since this window sits just behind) throws a soft `CALayer` shadow that spills past
/// the window edges into the surrounding `shadowPad`. Only `shadowOpacity` is animated.
private final class ShadowCasterView: NSView {
    /// Distance from the view edge in to the fill rect — matches `WindowCoordinator.shadowPad`
    /// so the fill lines up exactly with the main window and the shadow spills into the rest.
    var pad: CGFloat = 60.0 { didSet { needsLayout = true } }
    /// Corner radius of the main window's visible edge, traced by the fill and shadow.
    var cornerRadius: CGFloat = 20.0 { didSet { needsLayout = true } }
    /// Full-strength (resting) shadow opacity; the initial value before any fade.
    var restingOpacity: Float = 0.30 {
        didSet { fillLayer.shadowOpacity = restingOpacity }
    }

    private let fillLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        // Fill colour is irrelevant to the shadow and is occluded by the main window; a
        // sliver could show at the very corners, so use the window background rather than a
        // stark black so any leak blends in. The shadow itself is always black.
        fillLayer.backgroundColor = NSColor.windowBackgroundColor.cgColor
        fillLayer.shadowColor = NSColor.black.cgColor
        fillLayer.shadowOffset = CGSize(width: 0, height: -8)
        fillLayer.shadowRadius = 18
        fillLayer.shadowOpacity = restingOpacity
        layer?.addSublayer(fillLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        withoutImplicitAnimation {
            fillLayer.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
    }

    override func layout() {
        super.layout()
        // Nudge the fill 0.5pt inside the main window's edge so its corners stay tucked
        // under the (opaque) window even if the real corner radius differs slightly.
        let rect = bounds.insetBy(dx: pad + 0.5, dy: pad + 0.5)
        withoutImplicitAnimation {
            fillLayer.frame = rect
            fillLayer.cornerRadius = cornerRadius
            fillLayer.shadowPath = CGPath(
                roundedRect: CGRect(origin: .zero, size: rect.size),
                cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil
            )
        }
    }

    /// Fades (or snaps) the shadow to `opacity`. Reads the presentation layer so a fade that
    /// interrupts another lands smoothly rather than jumping to the model value first.
    func setShadowOpacity(_ opacity: Float, animated: Bool) {
        if animated {
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = fillLayer.presentation()?.shadowOpacity ?? fillLayer.shadowOpacity
            animation.toValue = opacity
            animation.duration = 0.28
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            fillLayer.add(animation, forKey: "shadowOpacity")
            fillLayer.shadowOpacity = opacity
        } else {
            withoutImplicitAnimation { fillLayer.shadowOpacity = opacity }
        }
    }

    private func withoutImplicitAnimation(_ body: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        body()
        CATransaction.commit()
    }
}
