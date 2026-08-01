import AppKit
import ApplicationServices
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
        // The system permission dialog appears above the requesting window: even
        // when Pika's secondary windows ride `.floating` (see `createSecondaryWindow`),
        // system dialogs sit above that level.
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

/// Shared owner of the loupe UI, ScreenCaptureKit capture loop, and the full-screen
/// catcher that drives cursor tracking and swallows the committing click.
final class PickerLoupeController {
    static let shared = PickerLoupeController()
    private init() {}

    let viewModel = LoupeViewModel()

    // The loupe is three stacked panels: a circular magnifier centred on the cursor, a
    // readout card beside it, and a full-screen catcher beneath both that swallows the
    // committing click so it never reaches the desktop.
    private var circlePanel: LoupeCirclePanel?
    private var cardPanel: LoupeCardPanel?
    private var catcher: LoupeClickCatcherPanel?
    private var completion: ((NSColor?) -> Void)?
    private var willChain = false

    // Keep-alive across a pair pick: after the foreground commit we expect the caller
    // to re-arm for the background almost immediately, so we don't tear the panel down.
    private var rearmSafety: Timer?

    // Key-event monitor (retained so it can be removed on teardown).
    private var localMonitors: [Any] = []

    // True while the loupe is up (shown, not torn down). A pair pick keeps this set across
    // the foreground → background handoff; a cancel/commit teardown clears it. `begin` uses
    // it to tell a re-arm (reuse the visible loupe) from a fresh pick (build it again) —
    // panels are held for reuse and stay non-nil after teardown, so their presence alone
    // can't distinguish the two.
    private var isActive = false

    // Set when we activated Pika (Accessibility not granted) to receive keys during a pick;
    // its value is the app to restore focus to on teardown.
    private var appToRestore: NSRunningApplication?

    // Capture state.
    private var configuredDisplayID: CGDirectDisplayID?
    private var baseFilter: SCContentFilter?
    private var loupeWindowIDs: [CGWindowID] = []
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
        if isActive {
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
        if circlePanel == nil { circlePanel = LoupeCirclePanel(viewModel: viewModel) }
        if cardPanel == nil { cardPanel = LoupeCardPanel(viewModel: viewModel) }
        if catcher == nil {
            let catcher = LoupeClickCatcherPanel()
            catcher.onCommit = { [weak self] in self?.commit() }
            catcher.onCancel = { [weak self] in self?.cancel() }
            catcher.onMoved = { [weak self] in self?.handlePointerMoved() }
            catcher.onScroll = { [weak self] event in self?.handleScroll(event) }
            self.catcher = catcher
        }

        // Order the catcher beneath the loupe (same window level) so it covers every other
        // app while the circle and card stay visible on top. The full-screen catcher takes
        // key status so Escape / zoom / nudge reach us without activating Pika.
        catcher?.cover(screens: NSScreen.screens)
        catcher?.orderFrontRegardless()
        cardPanel?.orderFrontRegardless()
        circlePanel?.orderFrontRegardless()

        loupeWindowIDs = [circlePanel?.windowNumber, cardPanel?.windowNumber, catcher?.windowNumber]
            .compactMap { $0 }
            .map { CGWindowID($0) }

        // Activate (fallback) before taking key status so the catcher stays key afterwards.
        activateForKeysIfNeeded()
        catcher?.makeKey()
        isActive = true
    }

    /// A non-activating panel only receives keys while Pika is frontmost. If Pika is trusted
    /// for Accessibility the global key monitor covers Escape/zoom/nudge without stealing
    /// focus; otherwise fall back to briefly activating Pika (restoring focus on teardown) so
    /// the local key monitor works — the pick already covers the screen with the catcher, so
    /// the sampled app going inactive for the pick's duration is acceptable.
    private func activateForKeysIfNeeded() {
        guard appToRestore == nil, !AXIsProcessTrusted() else { return }
        appToRestore = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
    }

    private func reposition() {
        circlePanel?.center(on: currentCursor)
        cardPanel?.position(near: currentCursor, circleRadius: (circlePanel?.diameter ?? 140) / 2)
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
        isActive = false
        rearmSafety?.invalidate()
        rearmSafety = nil
        removeMonitors()
        isCapturing = false
        pendingCapture = false
        configuredDisplayID = nil
        baseFilter = nil
        circlePanel?.orderOut(nil)
        cardPanel?.orderOut(nil)
        catcher?.orderOut(nil)

        // Restore focus to whatever app we took it from for key handling.
        if let appToRestore {
            appToRestore.activate()
            self.appToRestore = nil
        }
    }

    // MARK: - Event monitors

    private func installMonitors() {
        guard localMonitors.isEmpty else { return }

        // Pointer movement, the committing click, scroll-to-zoom and right-click cancel are
        // all handled by the full-screen catcher (see `LoupeClickCatcherPanel`), which sits
        // in front of every other app and so receives — and can swallow — those events.
        //
        // Keys need two monitors. The local one fires when Pika holds keyboard focus (and can
        // swallow the keys it handles). The global one fires when another app is frontmost —
        // it only delivers events if Pika is trusted for Accessibility, and can't swallow, so
        // it's a best-effort path for Escape/zoom/nudge while picking over another app. When
        // Accessibility isn't granted, `showPanel` activates Pika instead so the local monitor
        // covers everything (see `activateForKeysIfNeeded`).
        let localKey = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            (self?.handleKeyDown(event) ?? false) ? nil : event
        }
        let globalKey = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            _ = self?.handleKeyDown(event)
        }
        localMonitors.append(contentsOf: [localKey, globalKey].compactMap { $0 })
    }

    private func removeMonitors() {
        for monitor in localMonitors {
            NSEvent.removeMonitor(monitor)
        }
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
        let scale = screen.backingScaleFactor

        // Capture a generous region at *native* resolution (output pixels == source device
        // pixels, so ScreenCaptureKit does no scaling), then crop the exact centre pixels
        // ourselves. Asking SCK for a tiny `pixelCount`-sized output made it resample and
        // blend neighbours — the magnified view looked soft and the sampled colour drifted
        // with the cursor's sub-pixel position. A pixel-exact crop is crisp and stable.
        let captureExtent = max(pixelCount + 8, 128) // device pixels captured around the cursor
        let config = SCStreamConfiguration()
        config.width = captureExtent
        config.height = captureExtent
        config.showsCursor = false
        config.sourceRect = sourceRect(centeredOn: cursor, screen: screen, extentPixels: captureExtent, scale: scale)
        config.colorSpaceName = captureColorSpaceName()

        do {
            let full = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
            let cropX = (full.width - pixelCount) / 2
            let cropY = (full.height - pixelCount) / 2
            let region = CGRect(x: cropX, y: cropY, width: pixelCount, height: pixelCount)
            let cropped = full.cropping(to: region) ?? full
            viewModel.image = cropped
            viewModel.sampleColor = Self.centerPixelColor(of: cropped) ?? viewModel.sampleColor
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
            let excluded = content.windows.filter { loupeWindowIDs.contains($0.windowID) }
            baseFilter = SCContentFilter(display: display, excludingWindows: excluded)
            configuredDisplayID = displayID
        } catch {
            baseFilter = nil
            configuredDisplayID = nil
        }
    }

    /// The source region to capture, in points, in the display's top-left coordinate space —
    /// `extentPixels` device pixels centred on the cursor, snapped to the device-pixel grid
    /// so the capture maps 1:1 to real pixels (no sub-pixel straddling, so no resampling).
    private func sourceRect(centeredOn cursorGlobal: NSPoint, screen: NSScreen, extentPixels: Int, scale: CGFloat) -> CGRect {
        let extentPts = CGFloat(extentPixels) / scale
        let localX = cursorGlobal.x - screen.frame.minX
        let localYBottom = cursorGlobal.y - screen.frame.minY
        let localYTop = screen.frame.height - localYBottom
        let originX = ((localX - extentPts / 2) * scale).rounded() / scale
        let originY = ((localYTop - extentPts / 2) * scale).rounded() / scale
        return CGRect(x: originX, y: originY, width: extentPts, height: extentPts)
    }

    /// Capture in a known colour space and convert deliberately in the commit path —
    /// sRGB by default, Display P3 when the accuracy preference calls for it.
    private func captureColorSpaceName() -> CFString {
        // Compare the NSColorSpace directly, the way the rest of the app does
        // (see PreferencesView `space == NSColorSpace.displayP3`). Substring-
        // matching `localizedName` for "P3" was fragile — e.g. "Adobe RGB (1998)"
        // never matched and silently fell through to sRGB.
        Defaults[.colorSpace] == .displayP3 ? CGColorSpace.displayP3 : CGColorSpace.sRGB
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
