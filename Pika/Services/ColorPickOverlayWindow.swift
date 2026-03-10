import Cocoa
import SwiftUI

class ColorPickOverlayWindow {
    private var infoPanel: NSPanel?
    private var crosshairPanel: NSPanel?
    private var dismissTimer: Timer?
    private var viewModel: ColorPickOverlayViewModel?

    func show(colorText: String, pickedColor: NSColor, nearCursor cursorPosition: NSPoint, duration: Double) {
        // Cancel any pending dismiss timer and close panels immediately
        dismissTimer?.invalidate()
        dismissTimer = nil
        infoPanel?.close()
        crosshairPanel?.close()
        infoPanel = nil
        crosshairPanel = nil

        let viewModel = ColorPickOverlayViewModel()
        self.viewModel = viewModel

        // Create info panel with color text
        let contentView = ColorPickOverlay(colorText: colorText, pickedColor: pickedColor, viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)

        hostingView.invalidateIntrinsicContentSize()
        let intrinsicSize = hostingView.intrinsicContentSize
        let panelWidth = intrinsicSize.width
        let panelHeight = intrinsicSize.height

        let infoPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        infoPanel.isFloatingPanel = true
        infoPanel.level = .popUpMenu
        infoPanel.backgroundColor = .clear
        infoPanel.isOpaque = false
        infoPanel.hasShadow = true
        infoPanel.titlebarAppearsTransparent = true
        infoPanel.titleVisibility = .hidden
        infoPanel.isMovable = false
        infoPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        infoPanel.contentView = hostingView

        // Create crosshair panel at cursor position
        let crosshairView = ColorPickCrosshair(pickedColor: pickedColor, viewModel: viewModel)
        let crosshairHostingView = NSHostingView(rootView: crosshairView)

        let crosshairSize: CGFloat = 20
        let crosshairPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: crosshairSize, height: crosshairSize),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        crosshairPanel.isFloatingPanel = true
        crosshairPanel.level = .popUpMenu
        crosshairPanel.backgroundColor = .clear
        crosshairPanel.isOpaque = false
        crosshairPanel.hasShadow = false
        crosshairPanel.titlebarAppearsTransparent = true
        crosshairPanel.titleVisibility = .hidden
        crosshairPanel.isMovable = false
        crosshairPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        crosshairPanel.contentView = crosshairHostingView

        let screen = NSScreen.screens.first { NSMouseInRect(cursorPosition, $0.frame, false) } ?? NSScreen.main

        if let screen = screen {
            let screenFrame = screen.visibleFrame
            let offset: CGFloat = 5

            // Position info panel offset from cursor
            var xPosition = cursorPosition.x + offset
            var yPosition = cursorPosition.y - panelHeight - offset

            if xPosition + panelWidth > screenFrame.maxX {
                xPosition = cursorPosition.x - panelWidth - offset
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

            infoPanel.setFrame(
                NSRect(x: xPosition, y: yPosition, width: panelWidth, height: panelHeight),
                display: true
            )

            // Position crosshair centered on cursor
            crosshairPanel.setFrame(
                NSRect(x: cursorPosition.x - crosshairSize / 2, y: cursorPosition.y - crosshairSize / 2, width: crosshairSize, height: crosshairSize),
                display: true
            )
        }

        infoPanel.orderFrontRegardless()
        crosshairPanel.orderFrontRegardless()

        self.infoPanel = infoPanel
        self.crosshairPanel = crosshairPanel

        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let infoPanel = infoPanel, let crosshairPanel = crosshairPanel, let viewModel = viewModel else { return }

        // Clear references immediately to prevent conflicts
        self.infoPanel = nil
        self.crosshairPanel = nil
        self.viewModel = nil

        viewModel.fadeOut {
            infoPanel.close()
            crosshairPanel.close()
        }
    }
}
