import AppKit
import SwiftUI

/// Forces every `NSScrollView` in the current window to use `.overlay` scrollers so they
/// float over content rather than reserving layout width — even when the user has macOS set
/// to "Always show scrollbars" (the default for mouse users).
///
/// `.background(ScrollerStyleEnforcer())` only sees its own enclosing scroll view via
/// `enclosingScrollView`, which doesn't always work in SwiftUI hosting hierarchies. This
/// implementation walks the whole window content view tree to be robust.
private struct ScrollerStyleEnforcer: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView {
        let view = NSView(frame: .zero)
        applyOnNextRunLoop(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        applyOnNextRunLoop(from: nsView)
    }

    private func applyOnNextRunLoop(from view: NSView) {
        DispatchQueue.main.async {
            guard let root = view.window?.contentView else { return }
            applyOverlayStyle(to: root)
        }
    }

    private func applyOverlayStyle(to view: NSView) {
        if let scroll = view as? NSScrollView {
            scroll.scrollerStyle = .overlay
            scroll.verticalScroller?.scrollerStyle = .overlay
            scroll.horizontalScroller?.scrollerStyle = .overlay
            scroll.autohidesScrollers = true
        }
        for subview in view.subviews {
            applyOverlayStyle(to: subview)
        }
    }
}

extension View {
    func forceOverlayScrollers() -> some View {
        background(ScrollerStyleEnforcer())
    }
}
