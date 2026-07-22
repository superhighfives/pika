import AppKit
import SwiftUI

/// The floating loupe card. A borderless, non-activating panel that follows the cursor
/// while a custom pick is active. It never steals focus from the app being sampled and
/// ignores mouse events, so the committing click lands on the app underneath — the
/// controller only observes it. It can still become key (without activating Pika) so it
/// can receive Escape / zoom / nudge keys.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
final class PickerLoupePanel: NSPanel {
    /// Gap between the cursor and the nearest card corner.
    private let cursorGap: CGFloat = 24
    private let hostingView: NSHostingView<PickerLoupeView>

    init(viewModel: LoupeViewModel) {
        hostingView = NSHostingView(rootView: PickerLoupeView(viewModel: viewModel))

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 260),
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

    // Borderless panels don't become key by default; the loupe needs key status to
    // receive Escape without activating Pika or deactivating the sampled app.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Positions the card offset from the cursor, flipping and clamping so it stays on
    /// the screen under the cursor.
    func position(near cursor: NSPoint) {
        let size = hostingView.fittingSize
        setContentSize(size)

        let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
        guard let frame = screen?.visibleFrame else {
            setFrameOrigin(NSPoint(x: cursor.x + cursorGap, y: cursor.y - size.height - cursorGap))
            return
        }

        // Prefer down-and-right of the cursor; flip toward whichever side has room.
        var originX = cursor.x + cursorGap
        var originY = cursor.y - size.height - cursorGap

        if originX + size.width > frame.maxX { originX = cursor.x - size.width - cursorGap }
        if originX < frame.minX { originX = frame.minX + 8 }
        if originX + size.width > frame.maxX { originX = frame.maxX - size.width - 8 }

        if originY < frame.minY { originY = cursor.y + cursorGap }
        if originY + size.height > frame.maxY { originY = frame.maxY - size.height - 8 }

        setFrameOrigin(NSPoint(x: originX, y: originY))
    }
}
