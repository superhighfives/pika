import Cocoa
import SwiftUI

class ColorPickOverlayWindow {
    private var panel: NSPanel?
    private var dismissTimer: Timer?

    func show(colorText: String, pickedColor: NSColor, nearCursor cursorPosition: NSPoint, duration: Double) {
        dismiss()

        let contentView = ColorPickOverlay(colorText: colorText, pickedColor: pickedColor)
        let hostingView = NSHostingView(rootView: contentView)

        hostingView.invalidateIntrinsicContentSize()
        let intrinsicSize = hostingView.intrinsicContentSize
        let panelWidth = intrinsicSize.width
        let panelHeight = intrinsicSize.height

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        panel.contentView = hostingView

        let screen = NSScreen.screens.first { NSMouseInRect(cursorPosition, $0.frame, false) } ?? NSScreen.main

        if let screen = screen {
            let screenFrame = screen.visibleFrame
            let offset: CGFloat = 20

            var xPosition = cursorPosition.x - offset
            var yPosition = cursorPosition.y - panelHeight - offset

            if xPosition + panelWidth > screenFrame.maxX {
                xPosition = cursorPosition.x - panelWidth
            }

            if xPosition < screenFrame.minX {
                xPosition = screenFrame.minX + 10
            }

            if yPosition < screenFrame.minY {
                yPosition = cursorPosition.y + offset
            }

            if yPosition + panelHeight > screenFrame.maxY {
                yPosition = screenFrame.maxY - panelHeight - 10
            }

            panel.setFrame(
                NSRect(x: xPosition, y: yPosition, width: panelWidth, height: panelHeight),
                display: true
            )
        }

        panel.orderFrontRegardless()

        self.panel = panel

        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.close()
        panel = nil
    }
}
