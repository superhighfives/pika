import AppKit
import SwiftUI

struct HorizontalScrollWheelAdapter: NSViewRepresentable {
    func makeNSView(context _: Context) -> ScrollCaptureView {
        ScrollCaptureView()
    }

    func updateNSView(_: ScrollCaptureView, context _: Context) {}

    final class ScrollCaptureView: NSView {
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil, monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                    self?.handle(event) ?? event
                }
            } else if window == nil, let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard event.window === window, let window else { return event }

            let pointInSelf = convert(event.locationInWindow, from: nil)
            guard bounds.contains(pointInSelf) else { return event }

            // Trackpads and Magic Mouse already deliver horizontal swipes natively;
            // only intervene for classic scroll wheels (non-precise deltas).
            guard !event.hasPreciseScrollingDeltas else { return event }
            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) { return event }

            guard let scrollView = enclosingScrollView(at: event.locationInWindow, in: window) else {
                return event
            }

            let deltaY = event.scrollingDeltaY
            guard deltaY != 0 else { return event }

            let clipView = scrollView.contentView
            let documentWidth = scrollView.documentView?.frame.width ?? 0
            let maxX = max(0, documentWidth - clipView.bounds.width)
            var origin = clipView.bounds.origin
            origin.x = min(maxX, max(0, origin.x - deltaY))
            clipView.setBoundsOrigin(origin)
            scrollView.reflectScrolledClipView(clipView)
            return nil
        }

        private func enclosingScrollView(at windowPoint: NSPoint, in window: NSWindow) -> NSScrollView? {
            var view = window.contentView?.hitTest(windowPoint)
            while let current = view {
                if let scrollView = current as? NSScrollView { return scrollView }
                view = current.superview
            }
            return nil
        }
    }
}

extension View {
    func translateVerticalScrollToHorizontal() -> some View {
        background(HorizontalScrollWheelAdapter().allowsHitTesting(false))
    }
}
