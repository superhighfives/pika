import ApplicationServices
import Cocoa
import Defaults
import SwiftUI

/// Helps grant a privacy permission by dragging Pika into System Settings' list. Opens the pane,
/// flies a Pika chip from where the user clicked into System Settings, then docks a panel inside
/// the bottom of its window ("Drag Pika into the … list above", with a row to drag). Dragging the
/// app in adds it already switched on, which saves finding it with + in a file dialog. The panel
/// follows the window, hides while the user is in another app, and closes once the permission is
/// granted, System Settings closes, or the user dismisses it.
@MainActor
final class PermissionDragHelper {
    enum Permission {
        case screenRecording, accessibility

        var paneURL: URL? {
            switch self {
            case .screenRecording:
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
            case .accessibility:
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
        }

        var instruction: String {
            switch self {
            case .screenRecording: PikaText.textPermissionDragScreenRecording
            case .accessibility: PikaText.textPermissionDragAccessibility
            }
        }

        /// Accessibility is live; Screen Recording only reports a grant after a relaunch, so its
        /// panel closes with System Settings instead.
        var isGranted: Bool {
            switch self {
            case .screenRecording: false
            case .accessibility: AXIsProcessTrusted()
            }
        }
    }

    static let shared = PermissionDragHelper()

    private var panel: NSPanel?
    private var flyer: NSPanel?
    private var timer: Timer?
    private var permission: Permission?
    /// When the panel was shown, so a System Settings that never opens doesn't leave it waiting.
    private var shownAt = Date()
    private var hasSeenSettingsWindow = false
    private var isFlying = false
    /// Where the user clicked, for the chip to fly from.
    private var flightStart = NSPoint.zero
    /// Puts a lowered floating window back once the user returns to it.
    private var restoreObserver: NSObjectProtocol?

    private static let settingsBundleID = "com.apple.systempreferences"
    /// The dock's height, and its inset from System Settings' window edges.
    private static let dockHeight: CGFloat = 128
    private static let inset: CGFloat = 12
    /// System Settings' sidebar, as a share of its window's width; the dock sits in the content
    /// area beside it.
    private static let sidebarShare: CGFloat = 0.315
    /// The draggable row inside the dock: its height, and its inset from the dock's edges.
    private static let rowHeight: CGFloat = 48
    private static let rowInset: CGFloat = 16

    func show(_ permission: Permission) {
        lowerFloatingWindow()
        flightStart = NSEvent.mouseLocation
        if let url = permission.paneURL { NSWorkspace.shared.open(url) }
        self.permission = permission
        shownAt = Date()
        hasSeenSettingsWindow = false

        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: PermissionDockView(instruction: permission.instruction) { [weak self] in
            self?.close()
        })
        // Shown by `tick` once System Settings is up and active, docked in its window.
        panel.orderOut(nil)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func close() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        flyer?.orderOut(nil)
        isFlying = false
        permission = nil
    }

    /// A floating splash or Settings window would sit over System Settings. Drop it to the
    /// normal level while the user is there, and restore it once they come back to it.
    private func lowerFloatingWindow() {
        guard let window = NSApp.keyWindow, window.level == .floating, window !== panel else { return }
        window.level = .normal
        if let restoreObserver { NotificationCenter.default.removeObserver(restoreObserver) }
        restoreObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                (note.object as? NSWindow)?.level = Defaults[.appFloating] ? .floating : .normal
                if let observer = self?.restoreObserver { NotificationCenter.default.removeObserver(observer) }
                self?.restoreObserver = nil
            }
        }
    }

    private static func makeFloatingPanel(_ rect: NSRect) -> NSPanel {
        let panel = NSPanel(contentRect: rect, styleMask: [.nonactivatingPanel, .borderless],
                            backing: .buffered, defer: false)
        // Above System Settings, without taking focus from it.
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // Not every Space: it belongs with System Settings, and `tick` shows it only while that's
        // the active app, so switching to another app doesn't leave it behind.
        panel.collectionBehavior = [.fullScreenAuxiliary]
        return panel
    }

    private func makePanel() -> NSPanel {
        Self.makeFloatingPanel(NSRect(x: 0, y: 0, width: 400, height: Self.dockHeight))
    }

    private func tick() {
        guard let permission, let panel else { return }
        if permission.isGranted {
            close()
            return
        }
        guard let frame = Self.settingsWindowFrame() else {
            // Closed after it opened, or never opened at all.
            if hasSeenSettingsWindow || Date().timeIntervalSince(shownAt) > 10 { close() }
            return
        }
        let dock = Self.dockFrame(in: frame)
        let settingsActive = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Self.settingsBundleID
        if !hasSeenSettingsWindow {
            // Wait for System Settings to come forward, then fly the chip in from the click.
            guard settingsActive else { return }
            hasSeenSettingsWindow = true
            panel.setFrame(dock, display: false)
            fly(to: Self.rowFrame(in: dock)) { [weak self] in self?.reveal() }
            return
        }
        guard !isFlying else { return }
        if panel.frame != dock { panel.setFrame(dock, display: true) }
        // Only while the user is in System Settings: switching to another app hides it, coming
        // back shows it again.
        if settingsActive, !panel.isVisible {
            panel.orderFrontRegardless()
        } else if !settingsActive, panel.isVisible {
            panel.orderOut(nil)
        }
    }

    /// Flies a Pika chip from where the user clicked to the dock's row.
    private func fly(to target: NSRect, completion: @escaping () -> Void) {
        let start = NSRect(x: flightStart.x - 110, y: flightStart.y - Self.rowHeight / 2,
                           width: 220, height: Self.rowHeight)
        let flyer = self.flyer ?? Self.makeFloatingPanel(start)
        self.flyer = flyer
        flyer.contentView = NSHostingView(rootView: PermissionChip())
        flyer.setFrame(start, display: true)
        flyer.alphaValue = 1
        flyer.orderFrontRegardless()
        isFlying = true
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0 : 0.55
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
            flyer.animator().setFrame(target, display: true)
        } completionHandler: {
            MainActor.assumeIsolated { completion() }
        }
    }

    /// Fades the dock in around the landed chip, then drops the chip.
    private func reveal() {
        guard let panel, permission != nil else { return }
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.flyer?.orderOut(nil)
                self?.isFlying = false
            }
        }
    }

    /// The bottom of System Settings' content area, beside its sidebar.
    private static func dockFrame(in frame: NSRect) -> NSRect {
        let left = frame.minX + (frame.width * sidebarShare).rounded() + inset
        return NSRect(x: left, y: frame.minY + inset, width: frame.maxX - inset - left, height: dockHeight)
    }

    /// Where the draggable row sits inside the dock, in screen coordinates.
    private static func rowFrame(in dock: NSRect) -> NSRect {
        NSRect(x: dock.minX + rowInset, y: dock.minY + rowInset,
               width: dock.width - rowInset * 2, height: rowHeight)
    }

    /// System Settings' main window in Cocoa coordinates. Window bounds are readable without
    /// Screen Recording permission; only titles and contents need it.
    private static func settingsWindowFrame() -> NSRect? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleID).first,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                       kCGNullWindowID) as? [[String: Any]]
        else { return nil }
        let primaryHeight = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height ?? 0
        let frames: [NSRect] = windows.compactMap { info in
            guard (info[kCGWindowOwnerPID as String] as? pid_t) == app.processIdentifier,
                  (info[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let originX = bounds["X"], let originY = bounds["Y"], let width = bounds["Width"],
                  let height = bounds["Height"], width > 200, height > 200
            else { return nil }
            // CoreGraphics measures from the top of the primary display, Cocoa from its bottom.
            return NSRect(x: originX, y: primaryHeight - originY - height, width: width, height: height)
        }
        return frames.max { $0.width * $0.height < $1.width * $1.height }
    }
}

/// Pika's icon and name: the row to drag into the list, and the chip that flies in.
private struct PermissionChip: View {
    private var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Pika"
    }

    var body: some View {
        HStack(spacing: 10.0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 28, height: 28)
            Text(name)
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
    }
}

/// The panel docked in System Settings: what to do, and the row to drag.
private struct PermissionDockView: View {
    let instruction: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(instruction)
                        .font(.system(size: 13, weight: .semibold))
                    Text(PikaText.textPermissionDragHint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PikaText.textPermissionDragClose)
            }
            Spacer(minLength: 0)
            PermissionChip()
                .frame(height: 48)
                // A file URL, as Finder drags an app: the format the privacy lists accept.
                .onDrag { NSItemProvider(object: Bundle.main.bundleURL as NSURL) }
                .help(instruction)
                .accessibilityLabel(instruction)
        }
        .padding(16.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18.0, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1))
        )
    }
}
