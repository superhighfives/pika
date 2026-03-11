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

        let (infoPanel, panelSize) = makeInfoPanel(colorText: colorText, pickedColor: pickedColor, viewModel: viewModel)
        let crosshairSize: CGFloat = 20
        let crosshairPanel = makeCrosshairPanel(pickedColor: pickedColor, viewModel: viewModel, size: crosshairSize)

        positionPanels(
            infoPanel: infoPanel, crosshairPanel: crosshairPanel,
            near: cursorPosition, panelSize: panelSize, crosshairSize: crosshairSize)

        infoPanel.orderFrontRegardless()
        crosshairPanel.orderFrontRegardless()

        self.infoPanel = infoPanel
        self.crosshairPanel = crosshairPanel

        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    private func makeInfoPanel(
        colorText: String, pickedColor: NSColor, viewModel: ColorPickOverlayViewModel
    ) -> (NSPanel, CGSize) {
        let contentView = ColorPickOverlay(colorText: colorText, pickedColor: pickedColor, viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)

        hostingView.invalidateIntrinsicContentSize()
        let intrinsicSize = hostingView.intrinsicContentSize

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: intrinsicSize.width, height: intrinsicSize.height),
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

        return (panel, intrinsicSize)
    }

    private func makeCrosshairPanel(
        pickedColor: NSColor, viewModel: ColorPickOverlayViewModel, size: CGFloat
    ) -> NSPanel {
        let crosshairView = ColorPickCrosshair(pickedColor: pickedColor, viewModel: viewModel)
        let hostingView = NSHostingView(rootView: crosshairView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingView

        return panel
    }

    private func positionPanels(
        infoPanel: NSPanel, crosshairPanel: NSPanel,
        near cursorPosition: NSPoint, panelSize: CGSize, crosshairSize: CGFloat
    ) {
        let screen = NSScreen.screens.first { NSMouseInRect(cursorPosition, $0.frame, false) } ?? NSScreen.main
        guard let screen = screen else { return }

        let screenFrame = screen.visibleFrame
        let offset: CGFloat = 5

        var xPosition = cursorPosition.x + offset
        var yPosition = cursorPosition.y - panelSize.height - offset

        if xPosition + panelSize.width > screenFrame.maxX {
            xPosition = cursorPosition.x - panelSize.width - offset
        }
        if xPosition < screenFrame.minX {
            xPosition = screenFrame.minX + 10
        }
        if yPosition < screenFrame.minY {
            yPosition = cursorPosition.y + offset
        }
        if yPosition + panelSize.height > screenFrame.maxY {
            yPosition = screenFrame.maxY - panelSize.height - 10
        }

        infoPanel.setFrame(
            NSRect(x: xPosition, y: yPosition, width: panelSize.width, height: panelSize.height),
            display: true)

        crosshairPanel.setFrame(
            NSRect(
                x: cursorPosition.x - crosshairSize / 2,
                y: cursorPosition.y - crosshairSize / 2,
                width: crosshairSize, height: crosshairSize),
            display: true)
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
