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

    // The loupe is two stacked panels: the lens (a circular magnifier with the readouts
    // engraved around its rim) centred on the cursor, and a full-screen catcher beneath it
    // that swallows the committing click so it never reaches the desktop.
    private var circlePanel: LoupeCirclePanel?
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

    // Tracks whether we've hidden the system cursor for the pick, so hide/show stay balanced.
    private var cursorHidden = false

    // Closest-colour-name lookup for the lens theme, built once per pick from the active list.
    private var colorNames: [ColorName] = []
    private var closestVector: ClosestVector?

    // Capture state.
    private var configuredDisplayID: CGDirectDisplayID?
    private var baseFilter: SCContentFilter?
    private var loupeWindowIDs: [CGWindowID] = []
    private var isCapturing = false
    private var pendingCapture = false
    private var currentCursor: NSPoint = .zero

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

        // Fresh pick: capture one frame *before* showing the loupe, so it appears already
        // showing the live sample — no flash of the previous pick's colour, no black frame,
        // and on a launch's first pick the macOS consent prompt appears ahead of the loupe.
        isCapturing = true
        Task { @MainActor in
            await self.performCapture()
            self.isCapturing = false
            // The pick may have been cancelled while the consent prompt was up.
            guard self.completion != nil else { self.teardown(); return }
            self.showPanel()
            self.installMonitors()
            // That frame was captured before the loupe existed; rebuild the filter so the
            // loupe windows are excluded from subsequent frames.
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
        if catcher == nil {
            let catcher = LoupeClickCatcherPanel()
            catcher.onCommit = { [weak self] in self?.commit() }
            catcher.onCancel = { [weak self] in self?.cancel() }
            catcher.onMoved = { [weak self] in self?.handlePointerMoved() }
            catcher.onScroll = { [weak self] event in self?.handleScroll(event) }
            self.catcher = catcher
        }

        // Order the catcher beneath the loupe (same window level) so it covers every other
        // app while the lens stays visible on top. The full-screen catcher takes key status
        // so Escape / zoom / nudge reach us without activating Pika.
        catcher?.cover(screens: NSScreen.screens)
        catcher?.orderFrontRegardless()
        circlePanel?.orderFrontRegardless()

        loupeWindowIDs = [circlePanel?.windowNumber, catcher?.windowNumber]
            .compactMap { $0 }
            .map { CGWindowID($0) }

        // Activate (fallback) before taking key status so the catcher stays key afterwards.
        activateForKeysIfNeeded()
        catcher?.makeKey()

        // The loupe circle sits on the cursor, so hide the system cursor for the pick.
        if !cursorHidden {
            CGDisplayHideCursor(CGMainDisplayID())
            cursorHidden = true
        }

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
        let scale = screenUnderCursor()?.backingScaleFactor ?? 2.0
        circlePanel?.center(on: currentCursor, scale: scale)
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
        if cursorHidden {
            CGDisplayShowCursor(CGMainDisplayID())
            cursorHidden = false
        }
        rearmSafety?.invalidate()
        rearmSafety = nil
        removeMonitors()
        isCapturing = false
        pendingCapture = false
        configuredDisplayID = nil
        baseFilter = nil
        // Rebuild the name lookup next pick so it reflects the active colour list.
        closestVector = nil
        colorNames = []
        circlePanel?.orderOut(nil)
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
        // Arrow keys nudge one device pixel; Shift+arrow jumps ten for coarser moves.
        let step = event.modifierFlags.contains(.shift) ? 10 : 1
        switch event.keyCode {
        case 53: // Escape
            cancel()
            return true
        case 24, 69: // = / + and keypad +
            viewModel.zoomIn(); requestCapture(); return true
        case 27, 78: // - and keypad -
            viewModel.zoomOut(); requestCapture(); return true
        case 123: nudge(dx: -step, dy: 0); return true // left
        case 124: nudge(dx: step, dy: 0); return true // right
        case 125: nudge(dx: 0, dy: -step); return true // down
        case 126: nudge(dx: 0, dy: step); return true // up
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

        // Capture the whole display at its *native* size and crop the exact pixels around the
        // cursor ourselves. Any `sourceRect` capture — even at a nominal 1:1 — makes
        // ScreenCaptureKit run a scaling pass that blends neighbours, so the magnifier looked
        // soft and the sampled colour drifted with the cursor's sub-pixel position. A
        // full-size capture uses no scaling pass, and `CGImage.cropping` is a pure pixel op,
        // so the pixels are hard-edged and the sample is the exact device pixel.
        let config = SCStreamConfiguration()
        config.width = Int((screen.frame.width * scale).rounded())
        config.height = Int((screen.frame.height * scale).rounded())
        config.showsCursor = false
        config.colorSpaceName = captureColorSpaceName()

        do {
            let full = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
            // Cursor position within the captured image (top-left origin, device pixels).
            let localX = (cursor.x - screen.frame.minX) * scale
            let localYTop = (screen.frame.height - (cursor.y - screen.frame.minY)) * scale
            let half = pixelCount / 2
            let maxX = max(0, full.width - pixelCount)
            let maxY = max(0, full.height - pixelCount)
            let originX = min(max(0, Int(localX.rounded()) - half), maxX)
            let originY = min(max(0, Int(localYTop.rounded()) - half), maxY)
            let region = CGRect(x: originX, y: originY, width: pixelCount, height: pixelCount)
            let cropped = full.cropping(to: region) ?? full
            viewModel.image = cropped
            viewModel.sampleColor = Self.centerPixelColor(of: cropped) ?? viewModel.sampleColor
            updateColorName()
        } catch {
            // Transient capture failures (display reconfigured, filter stale) are ignored;
            // the next mouse move retries. Force a filter rebuild so we recover.
            configuredDisplayID = nil
        }
    }

    /// Updates the closest colour name for the sample (both themes show it). The lookup
    /// vector is built once per pick from the active colour list.
    private func updateColorName() {
        if closestVector == nil {
            colorNames = ColorNamesManager.shared.currentColorNames()
            closestVector = ClosestVector(colorNames.map { $0.color.toRGB8BitArray() })
        }
        guard let closestVector, !colorNames.isEmpty else {
            viewModel.colorName = ""
            return
        }
        let index = closestVector.compare(viewModel.sampleColor)
        if colorNames.indices.contains(index) {
            viewModel.colorName = colorNames[index].name
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
        let x = max(0, image.width / 2)
        let y = max(0, image.height / 2)

        // Read the raw pixel and build the colour in the image's *exact* colour space (the
        // one we captured in — sRGB or Display P3). `NSBitmapImageRep.colorAt` reinterprets
        // the pixel through an intermediate device/calibrated space, so the sampled colour
        // didn't match what was on screen and drifted when re-picking Pika's own rendered
        // swatch. Anything but the standard ScreenCaptureKit layout falls back to colorAt.
        func fallback() -> NSColor? {
            NSBitmapImageRep(cgImage: image).colorAt(x: x, y: y)
        }

        guard image.bitsPerComponent == 8, image.bitsPerPixel == 32,
              let cgColorSpace = image.colorSpace,
              let colorSpace = NSColorSpace(cgColorSpace: cgColorSpace),
              let data = image.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data)
        else { return fallback() }

        // ScreenCaptureKit hands back 32-bit BGRA (little-endian, alpha-first); screen
        // pixels are opaque, so no un-premultiply is needed.
        let alphaFirst = image.alphaInfo == .premultipliedFirst || image.alphaInfo == .first
            || image.alphaInfo == .noneSkipFirst
        guard image.bitmapInfo.intersection(.byteOrderMask) == .byteOrder32Little, alphaFirst
        else { return fallback() }

        let offset = y * image.bytesPerRow + x * 4
        let blue = CGFloat(ptr[offset]) / 255.0
        let green = CGFloat(ptr[offset + 1]) / 255.0
        let red = CGFloat(ptr[offset + 2]) / 255.0
        return NSColor(colorSpace: colorSpace, components: [red, green, blue, 1.0], count: 4)
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
    @Published var colorName: String = ""
    @Published var target: Eyedropper.Types = .foreground
    @Published var comparison: NSColor?
    @Published var pixelCount: Int = 15

    private let minPixels = 5
    private let maxPixels = 41

    func zoomIn() { pixelCount = max(minPixels, pixelCount - 2) }
    func zoomOut() { pixelCount = min(maxPixels, pixelCount + 2) }
}
