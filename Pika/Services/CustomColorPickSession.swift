import AppKit
import Defaults
import ScreenCaptureKit
import SwiftUI

/// The Pika-native loupe picker. Conforms to `ColorPickSession` and forwards to the
/// shared `PickerLoupeController`, which owns the capture engine, event monitors and
/// floating panel. Keeping that state in a singleton lets the loupe stay visible
/// across a foreground → background pair pick instead of tearing down between shots.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
final class CustomColorPickSession: ColorPickSession {
    func begin(
        target: Eyedropper.Types,
        comparison: NSColor?,
        willChain: Bool,
        completion: @escaping (NSColor?) -> Void
    ) {
        PickerLoupeController.shared.begin(
            target: target,
            comparison: comparison,
            willChain: willChain,
            completion: completion
        )
    }

    func cancel() {
        PickerLoupeController.shared.cancel()
    }

    // MARK: - Permission

    /// The custom picker is only usable once Screen Recording (TCC) is granted.
    static var isAvailable: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Requests Screen Recording permission, calling back on the main thread with the
    /// result. Used by the enabling flow (Settings / splash). `CGRequestScreenCaptureAccess`
    /// blocks until the user responds the first time, so it runs off the main thread.
    ///
    /// Note: a first-time grant only takes effect after the app relaunches, so this
    /// typically calls back `false` even when the user goes on to allow it in System
    /// Settings — the caller surfaces relaunch guidance in that case.
    static func requestAccess(_ completion: @escaping (Bool) -> Void) {
        if CGPreflightScreenCaptureAccess() {
            completion(true)
            return
        }
        // The system permission dialog appears above the requesting window because
        // Pika's secondary windows sit at `.normal` level (see `createSecondaryWindow`),
        // not elevated above system dialogs.
        DispatchQueue.global(qos: .userInitiated).async {
            let granted = CGRequestScreenCaptureAccess()
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Relaunches Pika so a newly granted Screen Recording permission takes effect (the
    /// running process caches the pre-grant state until it restarts). Sandbox-safe: asks
    /// the workspace to spawn a fresh instance, then terminates this one.
    static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    private static var didNotePermissionRevert = false

    /// Explains once, per launch, that the picker fell back to the system sampler
    /// because Screen Recording permission was revoked.
    static func notePermissionRevertedOnce() {
        guard !didNotePermissionRevert else { return }
        didNotePermissionRevert = true
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = PikaText.textPickerCustomRevertedTitle
            alert.informativeText = PikaText.textPickerCustomRevertedBody
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}

/// Shared owner of the loupe UI, ScreenCaptureKit capture loop, and global/local event
/// monitors used to track the cursor and observe the committing click.
final class PickerLoupeController {
    static let shared = PickerLoupeController()
    private init() {}

    let viewModel = LoupeViewModel()

    private var panel: PickerLoupePanel?
    private var completion: ((NSColor?) -> Void)?
    private var willChain = false

    // Keep-alive across a pair pick: after the foreground commit we expect the caller
    // to re-arm for the background almost immediately, so we don't tear the panel down.
    private var rearmSafety: Timer?

    // Event monitors (retained so they can be removed on teardown).
    private var globalMonitors: [Any] = []
    private var localMonitors: [Any] = []

    // Capture state.
    private var configuredDisplayID: CGDirectDisplayID?
    private var baseFilter: SCContentFilter?
    private var loupeWindowID: CGWindowID?
    private var isCapturing = false
    private var pendingCapture = false
    private var currentCursor: NSPoint = .zero

    // macOS shows its screen-capture consent the first time an app captures in a launch
    // session. We prime it on the first pick — capturing a frame *before* the loupe is
    // shown — so the prompt appears ahead of the loupe rather than over a black one.
    // Once primed, later picks show the loupe immediately. Reset each launch.
    private static var didPrimeConsent = false

    // MARK: - Session lifecycle

    func begin(
        target: Eyedropper.Types,
        comparison: NSColor?,
        willChain: Bool,
        completion: @escaping (NSColor?) -> Void
    ) {
        self.completion = completion
        self.willChain = willChain
        rearmSafety?.invalidate()
        rearmSafety = nil

        viewModel.target = target
        viewModel.comparison = comparison
        currentCursor = NSEvent.mouseLocation

        // Pair-pick re-arm: the loupe is already up, so just refresh it.
        if panel != nil, !globalMonitors.isEmpty {
            reposition()
            requestCapture()
            return
        }

        // Consent already primed this launch: show the loupe immediately (original flow).
        if Self.didPrimeConsent {
            showPanel()
            installMonitors()
            reposition()
            requestCapture()
            return
        }

        // First pick of the launch: capture one frame *before* showing the loupe so the
        // macOS screen-capture consent prompt appears ahead of the loupe, not over a black
        // one. The loupe then appears already showing a sample.
        isCapturing = true
        Task { @MainActor in
            await self.performCapture()
            self.isCapturing = false
            Self.didPrimeConsent = true
            // The pick may have been cancelled while the consent prompt was up.
            guard self.completion != nil else { self.teardown(); return }
            self.showPanel()
            self.installMonitors()
            // The priming frame was captured before the loupe existed; rebuild the filter
            // so the loupe window is excluded from subsequent frames.
            self.configuredDisplayID = nil
            self.reposition()
            self.requestCapture()
        }
    }

    func cancel() {
        finish(with: nil)
    }

    // MARK: - Panel

    private func showPanel() {
        if panel == nil {
            let panel = PickerLoupePanel(viewModel: viewModel)
            self.panel = panel
        }
        guard let panel = panel else { return }
        panel.orderFrontRegardless()
        panel.makeKey()
        loupeWindowID = CGWindowID(panel.windowNumber)
    }

    private func reposition() {
        panel?.position(near: currentCursor)
    }

    // MARK: - Commit / cancel / teardown

    private func commit() {
        finish(with: viewModel.sampleColor)
    }

    private func finish(with color: NSColor?) {
        let callback = completion
        completion = nil

        if color != nil, willChain {
            // A foreground pick that hands off to the background: keep the loupe up so
            // the next `begin` reuses it. Guard against a handoff that never arrives.
            rearmSafety?.invalidate()
            rearmSafety = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.teardown()
            }
        } else {
            teardown()
        }

        callback?(color)
    }

    private func teardown() {
        rearmSafety?.invalidate()
        rearmSafety = nil
        removeMonitors()
        isCapturing = false
        pendingCapture = false
        configuredDisplayID = nil
        baseFilter = nil
        panel?.orderOut(nil)
    }

    // MARK: - Event monitors

    private func installMonitors() {
        guard globalMonitors.isEmpty, localMonitors.isEmpty else { return }

        let moveMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        let clickMask: NSEvent.EventTypeMask = [.leftMouseDown]
        let cancelMask: NSEvent.EventTypeMask = [.rightMouseDown]

        globalMonitors.append(contentsOf: [
            NSEvent.addGlobalMonitorForEvents(matching: moveMask) { [weak self] _ in
                self?.handlePointerMoved()
            },
            NSEvent.addGlobalMonitorForEvents(matching: clickMask) { [weak self] _ in
                self?.commit()
            },
            NSEvent.addGlobalMonitorForEvents(matching: cancelMask) { [weak self] _ in
                self?.cancel()
            },
            NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
                self?.handleScroll(event)
            },
        ].compactMap { $0 })

        // Local monitors cover events delivered to Pika's own windows (including our
        // key loupe panel — that's where the Escape / zoom / nudge keys arrive).
        let localMove = NSEvent.addLocalMonitorForEvents(matching: moveMask) { [weak self] event in
            self?.handlePointerMoved()
            return event
        }
        let localClick = NSEvent.addLocalMonitorForEvents(matching: clickMask) { [weak self] event in
            self?.commit()
            return event
        }
        let localKey = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            (self?.handleKeyDown(event) ?? false) ? nil : event
        }
        let localScroll = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            self?.handleScroll(event)
            return event
        }
        localMonitors.append(contentsOf: [localMove, localClick, localKey, localScroll].compactMap { $0 })
    }

    private func removeMonitors() {
        for monitor in globalMonitors {
            NSEvent.removeMonitor(monitor)
        }
        for monitor in localMonitors {
            NSEvent.removeMonitor(monitor)
        }
        globalMonitors.removeAll()
        localMonitors.removeAll()
    }

    private func handlePointerMoved() {
        currentCursor = NSEvent.mouseLocation
        reposition()
        requestCapture()
    }

    private func handleScroll(_ event: NSEvent) {
        // Scroll up zooms in (fewer pixels across), down zooms out.
        if event.deltaY > 0 {
            viewModel.zoomIn()
        } else if event.deltaY < 0 {
            viewModel.zoomOut()
        }
        requestCapture()
    }

    /// Returns `true` when the key was handled (and should be swallowed).
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 53: // Escape
            cancel()
            return true
        case 24, 69: // = / + and keypad +
            viewModel.zoomIn(); requestCapture(); return true
        case 27, 78: // - and keypad -
            viewModel.zoomOut(); requestCapture(); return true
        case 123: nudge(dx: -1, dy: 0); return true // left
        case 124: nudge(dx: 1, dy: 0); return true // right
        case 125: nudge(dx: 0, dy: -1); return true // down
        case 126: nudge(dx: 0, dy: 1); return true // up
        default:
            return false
        }
    }

    /// Nudges the sample point by one device pixel by warping the cursor, for precise
    /// single-pixel picks. `dy` is in Cocoa orientation (up is positive).
    private func nudge(dx: Int, dy: Int) {
        guard let screen = screenUnderCursor() else { return }
        let step = 1.0 / screen.backingScaleFactor
        let target = NSPoint(x: currentCursor.x + CGFloat(dx) * step,
                             y: currentCursor.y + CGFloat(dy) * step)
        // CGWarp uses a top-left origin anchored on the primary display.
        let primaryHeight = (NSScreen.screens.first { $0.frame.origin == .zero } ?? screen).frame.height
        CGWarpMouseCursorPosition(CGPoint(x: target.x, y: primaryHeight - target.y))
        currentCursor = target
        reposition()
        requestCapture()
    }

    // MARK: - Capture

    private func screenUnderCursor() -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(currentCursor, $0.frame, false) } ?? NSScreen.main
    }

    private func requestCapture() {
        guard !isCapturing else { pendingCapture = true; return }
        isCapturing = true
        Task { @MainActor in
            await performCapture()
            isCapturing = false
            if pendingCapture {
                pendingCapture = false
                requestCapture()
            }
        }
    }

    @MainActor
    private func performCapture() async {
        let cursor = currentCursor
        guard let screen = screenUnderCursor() else { return }
        let displayID = screen.displayID

        if configuredDisplayID != displayID || baseFilter == nil {
            await configureFilter(for: displayID)
        }
        guard let filter = baseFilter else { return }

        let pixelCount = viewModel.pixelCount
        let config = SCStreamConfiguration()
        config.width = pixelCount
        config.height = pixelCount
        config.showsCursor = false
        config.sourceRect = sourceRect(forCursor: cursor, screen: screen, pixelCount: pixelCount)
        config.colorSpaceName = captureColorSpaceName()

        do {
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
            viewModel.image = image
            viewModel.sampleColor = Self.centerPixelColor(of: image) ?? viewModel.sampleColor
        } catch {
            // Transient capture failures (display reconfigured, filter stale) are ignored;
            // the next mouse move retries. Force a filter rebuild so we recover.
            configuredDisplayID = nil
        }
    }

    private func configureFilter(for displayID: CGDirectDisplayID) async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else { return }
            let excluded = content.windows.filter { $0.windowID == loupeWindowID }
            baseFilter = SCContentFilter(display: display, excludingWindows: excluded)
            configuredDisplayID = displayID
        } catch {
            baseFilter = nil
            configuredDisplayID = nil
        }
    }

    /// The source region to capture, in points, in the display's top-left coordinate
    /// space. Sized so it holds exactly `pixelCount` device pixels centred on the cursor.
    private func sourceRect(forCursor cursorGlobal: NSPoint, screen: NSScreen, pixelCount: Int) -> CGRect {
        let scale = screen.backingScaleFactor
        let regionPts = CGFloat(pixelCount) / scale
        let localX = cursorGlobal.x - screen.frame.minX
        let localYBottom = cursorGlobal.y - screen.frame.minY
        let localYTop = screen.frame.height - localYBottom
        return CGRect(
            x: localX - regionPts / 2,
            y: localYTop - regionPts / 2,
            width: regionPts,
            height: regionPts
        )
    }

    /// Capture in a known colour space and convert deliberately in the commit path —
    /// sRGB by default, Display P3 when the accuracy preference calls for it.
    private func captureColorSpaceName() -> CFString {
        let name = Defaults[.colorSpace].localizedName ?? ""
        return name.localizedCaseInsensitiveContains("P3") ? CGColorSpace.displayP3 : CGColorSpace.sRGB
    }

    static func centerPixelColor(of image: CGImage) -> NSColor? {
        let rep = NSBitmapImageRep(cgImage: image)
        let centerX = max(0, image.width / 2)
        let centerY = max(0, image.height / 2)
        return rep.colorAt(x: centerX, y: centerY)
    }
}

extension NSScreen {
    /// The `CGDirectDisplayID` backing this screen.
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()
    }
}

/// Observable state driving the loupe SwiftUI view. Updated on the main thread by the
/// controller after each capture.
final class LoupeViewModel: ObservableObject {
    @Published var image: CGImage?
    @Published var sampleColor: NSColor = .black
    @Published var target: Eyedropper.Types = .foreground
    @Published var comparison: NSColor?
    @Published var pixelCount: Int = 15

    private let minPixels = 5
    private let maxPixels = 41

    func zoomIn() { pixelCount = max(minPixels, pixelCount - 2) }
    func zoomOut() { pixelCount = min(maxPixels, pixelCount + 2) }
}
