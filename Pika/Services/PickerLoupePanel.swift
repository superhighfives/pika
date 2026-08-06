import AppKit
import SwiftUI

/// The circular magnifier panel, centred on the cursor (system-loupe style). Borderless,
/// non-activating, and ignores mouse events so the committing click lands on the
/// full-screen catcher beneath it. It can still become key (without activating Pika) so
/// it receives Escape / zoom / nudge keys.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
final class LoupeCirclePanel: NSPanel {
    private let hostingView: NSHostingView<LoupeCircle>

    init(viewModel: LoupeViewModel) {
        hostingView = NSHostingView(rootView: LoupeCircle(viewModel: viewModel))

        let side = LoupeCircle.totalSize
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: side, height: side),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false // LoupeCircle draws its own shadow inside the padded frame.
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovable = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        contentView = hostingView
    }

    // Borderless panels don't become key by default; the loupe needs key status to
    // receive Escape without activating Pika or deactivating the sampled app.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Centres the disc on the cursor. The padded frame is symmetric, so centring the
    /// window centres the circle (and its sampled centre pixel) on the cursor.
    ///
    /// The origin is snapped to the device-pixel grid: the magnified image is nearest-
    /// neighbour pixel-art, and a fractional window origin composites it at a sub-pixel
    /// offset, which the compositor anti-aliases — so it looks crisp at some cursor
    /// positions and blurs when the cursor sits half a device pixel over. Snapping keeps it
    /// hard-edged everywhere. (`NSEvent.mouseLocation` is sub-pixel, hence the fractional origin.)
    func center(on cursor: NSPoint, scale: CGFloat) {
        let size = frame.size
        let rawX = cursor.x - size.width / 2
        let rawY = cursor.y - size.height / 2
        setFrameOrigin(NSPoint(x: (rawX * scale).rounded() / scale,
                               y: (rawY * scale).rounded() / scale))
    }
}

/// The readout card panel, tucked beside the loupe circle for the `.card` theme. Display-only:
/// borderless, non-activating, and ignores mouse events.
final class LoupeCardPanel: NSPanel {
    private let hostingView: NSHostingView<LoupeReadoutCard>
    /// Gap between the circle's edge and the nearest card edge.
    private let gap: CGFloat = 14

    init(viewModel: LoupeViewModel) {
        hostingView = NSHostingView(rootView: LoupeReadoutCard(viewModel: viewModel))

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 176, height: 96),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovable = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        contentView = hostingView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Positions the card beside the cursor, clear of the circle, flipping and clamping so
    /// it stays on the screen under the cursor.
    func position(near cursor: NSPoint, circleRadius: CGFloat) {
        let size = hostingView.fittingSize
        setContentSize(size)

        let clearance = circleRadius + gap
        let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
        guard let frame = screen?.visibleFrame else {
            setFrameOrigin(NSPoint(x: cursor.x + clearance, y: cursor.y - size.height / 2))
            return
        }

        // Prefer to the right of the circle, vertically centred on the cursor; flip to the
        // left near the right edge, then clamp on both axes.
        var originX = cursor.x + clearance
        var originY = cursor.y - size.height / 2

        if originX + size.width > frame.maxX { originX = cursor.x - clearance - size.width }
        if originX < frame.minX { originX = frame.minX + 8 }
        if originX + size.width > frame.maxX { originX = frame.maxX - size.width - 8 }

        if originY < frame.minY { originY = frame.minY + 8 }
        if originY + size.height > frame.maxY { originY = frame.maxY - size.height - 8 }

        setFrameOrigin(NSPoint(x: originX, y: originY))
    }
}

/// A full-screen, transparent panel that sits above every other app (but below the loupe)
/// while a pick is active. Its whole job is to *consume* the committing click so it never
/// reaches the desktop / app underneath — global `NSEvent` monitors can only observe the
/// click, not swallow it. It also drives cursor tracking, scroll-to-zoom, and right-click
/// cancel, since with the catcher in front those events are delivered locally to Pika.
final class LoupeClickCatcherPanel: NSPanel {
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onMoved: (() -> Void)?
    var onScroll: ((NSEvent) -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Same level as the loupe panels. The controller keeps the catcher ordered front-most
        // (re-asserting it after the card panel re-orders itself on cursor moves) so it always
        // swallows clicks/scroll; being transparent, it doesn't hide the lens. A non-activating
        // panel at this level can still become key for Escape/zoom/nudge — pushing it to a
        // higher level breaks that, leaking scroll and keys to the app behind.
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false // The whole point: receive (and swallow) the click.
        acceptsMouseMovedEvents = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let view = LoupeClickCatcherView()
        view.owner = self
        contentView = view
    }

    // Becomes key (without activating Pika) so Escape / zoom / nudge reach the controller's
    // key monitor while a pick is active — it's the full-screen surface in front of every
    // other window, so it's the natural key window for the pick.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Covers the bounding rect of all screens so a click anywhere is intercepted.
    func cover(screens: [NSScreen]) {
        let union = screens.reduce(CGRect.null) { $0.union($1.frame) }
        let target = union.isNull ? (NSScreen.main?.frame ?? .zero) : union
        setFrame(target, display: false)
    }
}

/// Backing view for `LoupeClickCatcherPanel`. Consumes mouse-down (by not forwarding to
/// `super`) so the click dies here instead of reaching the desktop, and reports pointer
/// movement via a tracking area so the loupe follows the cursor.
private final class LoupeClickCatcherView: NSView {
    weak var owner: LoupeClickCatcherPanel?
    private var trackingAreaRef: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }
    // Deliver (and let us consume) the very first click even though the catcher isn't the
    // active window — otherwise the first click would just activate it and slip through.
    override func acceptsFirstMouse(for _: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef { removeTrackingArea(trackingAreaRef) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseMoved(with _: NSEvent) { owner?.onMoved?() }
    override func mouseDragged(with _: NSEvent) { owner?.onMoved?() }
    override func mouseDown(with _: NSEvent) { owner?.onCommit?() } // consumed (no super).
    override func rightMouseDown(with _: NSEvent) { owner?.onCancel?() } // consumed (no super).
    override func scrollWheel(with event: NSEvent) { owner?.onScroll?(event) }
}
