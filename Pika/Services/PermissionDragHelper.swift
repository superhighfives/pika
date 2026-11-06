import ApplicationServices
import Cocoa
import Defaults
import SwiftUI

/// A small panel beside System Settings with Pika's icon, to drag into a privacy list. Dragging
/// the app in adds it already switched on, which saves finding it with + in a file dialog.
/// Opens the pane itself, follows the System Settings window, and closes once the permission
/// is granted, System Settings closes, or the user dismisses it, and hides while the user is in
/// another app.
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

        var message: String {
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
    private var timer: Timer?
    private var permission: Permission?
    /// When the panel was shown, so a System Settings that never opens doesn't leave it waiting.
    private var shownAt = Date()
    private var hasSeenSettingsWindow = false
    /// Puts a lowered floating window back once the user returns to it.
    private var restoreObserver: NSObjectProtocol?

    private static let size = NSSize(width: 300, height: 92)
    private static let settingsBundleID = "com.apple.systempreferences"

    func show(_ permission: Permission) {
        lowerFloatingWindow()
        if let url = permission.paneURL { NSWorkspace.shared.open(url) }
        self.permission = permission
        shownAt = Date()
        hasSeenSettingsWindow = false

        let panel = self.panel ?? makePanel()
        self.panel = panel
        let host = NSHostingView(rootView: PermissionDragView(message: permission.message) { [weak self] in
            self?.close()
        })
        host.frame = NSRect(origin: .zero, size: Self.size)
        panel.contentView = host
        // Shown by `tick` once System Settings is up and active, beside its window.
        panel.orderOut(nil)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func close() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
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

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        // Above System Settings, without taking focus from it.
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // Not every Space: it belongs with System Settings, and `tick` shows it only while that's
        // the active app, so switching to another app or Space doesn't leave it behind.
        panel.collectionBehavior = [.fullScreenAuxiliary]
        return panel
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
        hasSeenSettingsWindow = true
        panel.setFrameOrigin(Self.origin(beside: frame))
        // Only beside System Settings while the user is in it: switching away hid it
        // (another app, another Space), coming back shows it again.
        let settingsActive = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Self.settingsBundleID
        if settingsActive, !panel.isVisible {
            panel.orderFrontRegardless()
        } else if !settingsActive, panel.isVisible {
            panel.orderOut(nil)
        }
    }

    /// Just under System Settings' window, centred on it, or above it when there's no room.
    private static func origin(beside frame: NSRect) -> NSPoint {
        let gap: CGFloat = 12
        let screen = NSScreen.screens.first { $0.frame.intersects(frame) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? frame
        var origin = NSPoint(x: frame.midX - size.width / 2, y: frame.minY - gap - size.height)
        if origin.y < visible.minY { origin.y = frame.maxY + gap }
        origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
        return origin
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

/// Pika's icon to drag, with what to do with it.
private struct PermissionDragView: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12.0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 52, height: 52)
                // A file URL, as Finder drags an app: the format the privacy lists accept.
                .onDrag { NSItemProvider(object: Bundle.main.bundleURL as NSURL) }
                .help(PikaText.textPermissionDragTitle)
                .accessibilityLabel(PikaText.textPermissionDragTitle)
            VStack(alignment: .leading, spacing: 3.0) {
                Text(PikaText.textPermissionDragTitle)
                    .font(.system(size: 13, weight: .semibold))
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14.0)
        .frame(width: 300, height: 92, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14.0, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(8.0)
            .accessibilityLabel(PikaText.textPermissionDragClose)
        }
    }
}
