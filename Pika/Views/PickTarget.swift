import AppKit
import SwiftUI

/// The full-size background pick target: owns its own `mouseDown` (mirroring `ScrubTextField`'s
/// approach in `EditableColorValue.swift`) so it can check the window's first responder *before*
/// deciding what a click means. A plain SwiftUI `Button` can't make that distinction — its action
/// fires unconditionally on tap, so a click intended to dismiss a focused colour-value field would
/// also fall through and start a new pick. If a field is currently being edited, this click's only
/// job is to end that edit (matching standard click-away-to-blur behaviour); otherwise it starts
/// a pick, same as before.
struct PickTarget: NSViewRepresentable {
    let onPick: () -> Void
    let onPressChange: (Bool) -> Void
    /// Called instead of `onPick` when the click's only job is to end an active edit session.
    /// AppKit's own `endEditing(for:)` resigns the field editor, but doesn't reliably notify
    /// `EditableColorValue`'s own focus-tracking state back up (its outline stays stuck showing
    /// "focused") — so the parent also needs an explicit nudge to clear that state itself.
    let onDismissEditing: () -> Void

    func makeNSView(context _: Context) -> PickTargetView {
        let view = PickTargetView()
        view.onPick = onPick
        view.onPressChange = onPressChange
        view.onDismissEditing = onDismissEditing
        return view
    }

    func updateNSView(_ view: PickTargetView, context _: Context) {
        view.onPick = onPick
        view.onPressChange = onPressChange
        view.onDismissEditing = onDismissEditing
    }

    final class PickTargetView: NSView, EditDismissingClickTarget {
        var onPick: (() -> Void)?
        var onPressChange: ((Bool) -> Void)?
        var onDismissEditing: (() -> Void)?

        override func mouseDown(with _: NSEvent) {
            if window?.firstResponder is NSText {
                window?.endEditing(for: nil)
                onDismissEditing?()
                return
            }

            onPressChange?(true)
            while true {
                guard let next = NSApp.nextEvent(
                    matching: [.leftMouseDragged, .leftMouseUp],
                    until: .distantFuture,
                    inMode: .eventTracking,
                    dequeue: true
                ) else {
                    onPressChange?(false)
                    return
                }
                if next.type == .leftMouseUp {
                    let point = convert(next.locationInWindow, from: nil)
                    onPressChange?(false)
                    if bounds.contains(point) { onPick?() }
                    return
                }
            }
        }
    }
}

/// A view whose own `mouseDown` already ends an active colour-field edit (and needs to see the
/// field still focused to know that's all the click should do), so `EditingClickAway` leaves
/// clicks on it alone.
protocol EditDismissingClickTarget: NSView {}

/// Click-away-to-blur for the colour fields. A click on a swatch already ended an edit (see
/// `PickTarget`), and a click on a button fired the button, but a click anywhere else in the
/// window — the labels, the contrast footer, the title bar — left the field focused. This
/// watches mouse-downs while a field is being edited and ends the edit for any that land
/// outside it. The click itself is never swallowed.
final class EditingClickAway {
    private var monitor: Any?

    func start(onDismiss: @escaping () -> Void) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let window = event.window else { return event }
            // `hitTest` takes a point in the superview's coordinates; the content view's
            // superview is the window's frame view, whose coordinates are the window's.
            let root = window.contentView?.superview ?? window.contentView
            let hit = root?.hitTest(event.locationInWindow)
            if Self.shouldEndEditing(firstResponder: window.firstResponder, clicked: hit) {
                window.endEditing(for: nil)
                onDismiss()
            }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    deinit { stop() }

    /// Whether a mouse-down on `clicked` should end the edit in progress: only when a colour
    /// field is the one being edited, and the click isn't on a colour field (which moves focus
    /// itself) or on a view that ends the edit in its own `mouseDown`.
    static func shouldEndEditing(firstResponder: NSResponder?, clicked: NSView?) -> Bool {
        guard let editor = firstResponder as? NSText, editor.delegate is ScrubTextField else { return false }
        var view = clicked
        while let current = view {
            if current is ScrubTextField || current is EditDismissingClickTarget { return false }
            view = current.superview
        }
        return true
    }
}

/// Swallows clicks over the readout block so they don't fall through to `PickTarget` and start
/// a screen pick. An AppKit view rather than a SwiftUI `contentShape`: `PickTarget` is itself an
/// `NSView` sitting in the same z-order, so the thing shadowing it has to win AppKit's own
/// hit-testing, not just SwiftUI's.
struct ClickShield: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView { ShieldView() }
    func updateNSView(_: NSView, context _: Context) {}

    final class ShieldView: NSView {
        // Absorb rather than forward: the readout's own fields sit in front of this and keep
        // receiving their clicks, but the labels, colour name, and the gaps between them no
        // longer act as a pick target.
        override func mouseDown(with _: NSEvent) {}
    }
}
