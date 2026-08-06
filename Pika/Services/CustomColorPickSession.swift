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
    // Only shown for the `.card` theme: the readout card tucked beside the magnifier.
    private var cardPanel: LoupeCardPanel?
    private var completion: ((NSColor?) -> Void)?
    private var willChain = false

    // Keep-alive across a pair pick: after the foreground commit we expect the caller
    // to re-arm for the background almost immediately, so we don't tear the panel down.
    private var rearmSafety: Timer?

    // Event capture. Preferred: a session `CGEventTap` that intercepts (and swallows) clicks,
    // scroll and keys globally — the only reliable way to catch input over *other* apps, which
    // needs Accessibility. Fallback (no Accessibility): `NSEvent` monitors, which only see input
    // dispatched to Pika (so they work over Pika's own window but not over other apps).
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
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

    // Live preview: while picking, the sampled colour is pushed into the target eyedropper so
    // the main window (swatches, colour names, and the contrast footer) updates in realtime.
    // `previewOriginal` is the target's colour at the start of the pick, restored on cancel.
    // History is gated on the `.colorPicked` notification (posted only at commit), so these
    // live writes never record undo steps.
    private var previewOriginal: NSColor?
    // Bumped whenever a pick begins or ends. `performCapture` is async, so a grab can resume
    // after the pick it belongs to was cancelled/committed; it applies its result only if the
    // generation still matches, so a straggler can't write a colour into a finished pick.
    private var pickGeneration = 0

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
        pickGeneration += 1
        self.completion = completion
        self.willChain = willChain
        rearmSafety?.invalidate()
        rearmSafety = nil

        viewModel.target = target
        viewModel.comparison = comparison
        viewModel.comparisonName = comparison.map { closestColorName(for: $0) } ?? ""
        // Snapshot the target's colour so a cancelled pick can restore it (we mutate it live
        // for the realtime preview below).
        previewOriginal = targetEyedropper?.color
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
        if cardPanel == nil { cardPanel = LoupeCardPanel(viewModel: viewModel) }
        if catcher == nil {
            let catcher = LoupeClickCatcherPanel()
            catcher.onCommit = { [weak self] in self?.commit() }
            catcher.onCancel = { [weak self] in self?.cancel() }
            catcher.onMoved = { [weak self] in self?.handlePointerMoved() }
            catcher.onScroll = { [weak self] event in self?.handleScroll(deltaY: Double(event.deltaY)) }
            self.catcher = catcher
        }

        // The catcher must be the front-most surface so it swallows clicks/scroll; it's ordered
        // last (after the circle and card) and re-fronted on every cursor move (see
        // `updateCardPanel`). Being transparent, it doesn't hide the lens. It also takes key
        // status so Escape / zoom / nudge reach us without activating Pika.
        catcher?.cover(screens: NSScreen.screens)
        circlePanel?.orderFrontRegardless()
        updateCardPanel()
        catcher?.orderFrontRegardless()

        loupeWindowIDs = [circlePanel?.windowNumber, cardPanel?.windowNumber, catcher?.windowNumber]
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
        updateCardPanel()
    }

    /// Shows the readout card beside the cursor for the `.card` theme (and positions it as the
    /// cursor moves); orders it away for the other themes, which carry their readouts on the disc.
    private func updateCardPanel() {
        guard let cardPanel else { return }
        if Defaults[.loupeTheme] == .card {
            cardPanel.position(near: currentCursor, circleRadius: LoupeCircle.cardGlass / 2)
            cardPanel.orderFrontRegardless()
            // The card just jumped to the front; keep the click-catcher above it so clicks and
            // scroll still land on the catcher rather than falling through.
            catcher?.orderFrontRegardless()
        } else {
            cardPanel.orderOut(nil)
        }
    }

    // MARK: - Commit / cancel / teardown

    /// The eyedropper being picked into, for the live preview. Resolved live so it always
    /// reflects `viewModel.target` (which flips to `.background` on a chained pair pick).
    private var targetEyedropper: Eyedropper? {
        guard let eyedroppers = AppDelegate.shared?.eyedroppers else { return nil }
        return viewModel.target == .foreground ? eyedroppers.foreground : eyedroppers.background
    }

    private func commit() {
        // Ignore stray events once the pick has ended (e.g. an orphaned catcher tracking area
        // still delivering after teardown): only a live pick has a completion.
        guard completion != nil else { return }
        finish(with: viewModel.sampleColor)
    }

    private func finish(with color: NSColor?) {
        guard completion != nil else { return }
        pickGeneration += 1 // invalidate any in-flight capture belonging to this pick
        // A cancelled pick reverts the live preview; a committed one keeps it (the caller's
        // completion re-sets the same colour and posts `.colorPicked`, which records history).
        if color == nil, let previewOriginal {
            targetEyedropper?.set(previewOriginal)
        }
        previewOriginal = nil

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
            // Commit/cancel can arrive from inside the CGEventTap callback (click, right-click,
            // Escape). Tearing down there removes the tap and its run-loop source from within the
            // tap's own callback, which leaves teardown half-done — the catcher keeps tracking and
            // the tap keeps firing. Mark inactive now (so nothing re-arms), and run teardown on the
            // next tick, cleanly outside the callback.
            isActive = false
            DispatchQueue.main.async { [weak self] in self?.teardown() }
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
        guard localMonitors.isEmpty, eventTap == nil else { return }
        // Prefer the global event tap; fall back to NSEvent monitors only if it can't be created
        // (Accessibility not granted). NSEvent monitors only see input dispatched to Pika, so
        // they work over Pika's own window but NOT over other apps — the tap works everywhere.
        // Pointer *movement* always rides the catcher's tracking area (`onMoved`).
        if installEventTap() { return }
        let localKey = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            (self?.handleKeyDown(event) ?? false) ? nil : event
        }
        let globalKey = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            _ = self?.handleKeyDown(event)
        }
        let scroll = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            self?.handleScroll(deltaY: Double(event.deltaY)); return nil
        }
        let leftDown = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            self?.commit(); return nil
        }
        let rightDown = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] _ in
            self?.cancel(); return nil
        }
        localMonitors.append(contentsOf: [localKey, globalKey, scroll, leftDown, rightDown].compactMap { $0 })
    }

    /// Installs a session-level event tap that intercepts and swallows clicks/scroll/keys for the
    /// duration of the pick, over ANY app. Returns false if it can't be created (no Accessibility).
    private func installEventTap() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.scrollWheel.rawValue)
            | (1 << CGEventType.keyDown.rawValue)
        // A capture-less closure so it bridges to a C function pointer; `self` arrives via refcon.
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<PickerLoupeController>.fromOpaque(refcon).takeUnretainedValue()
            return controller.handleTapEvent(type: type, event: event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap, // .defaultTap can alter/discard events; requires Accessibility
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        eventTapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    /// Handles a tapped event on the main run loop. Returns nil to swallow, or the event to pass.
    private func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .leftMouseDown:
            commit(); return nil
        case .rightMouseDown:
            cancel(); return nil
        case .scrollWheel:
            handleScroll(deltaY: event.getDoubleValueField(.scrollWheelEventDeltaAxis1)); return nil
        case .keyDown:
            let handled = NSEvent(cgEvent: event).map { handleKeyDown($0) } ?? false
            return handled ? nil : Unmanaged.passUnretained(event)
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func removeMonitors() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let eventTapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes) }
            self.eventTap = nil
            eventTapSource = nil
        }
        for monitor in localMonitors {
            NSEvent.removeMonitor(monitor)
        }
        localMonitors.removeAll()
    }

    private func handlePointerMoved() {
        // The catcher's tracking area can keep firing after teardown (orderOut doesn't always
        // stop it); ignore moves unless a pick is live so the preview can't drift afterwards.
        guard isActive else { return }
        currentCursor = NSEvent.mouseLocation
        reposition()
        requestCapture()
    }

    private func handleScroll(deltaY: Double) {
        // Scroll up zooms in (fewer pixels across), down zooms out.
        if deltaY > 0 {
            viewModel.zoomIn()
        } else if deltaY < 0 {
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
        case 36, 76: // Return and keypad Enter — commit the current sample (pairs with arrow nudging)
            commit()
            return true
        case 24, 69: // = / + and keypad +
            viewModel.zoomIn(); requestCapture(); return true
        case 27, 78: // - and keypad -
            viewModel.zoomOut(); requestCapture(); return true
        case 123: nudge(dx: -step, dy: 0); return true // left
        case 124: nudge(dx: step, dy: 0); return true // right
        case 125: nudge(dx: 0, dy: -step); return true // down
        case 126: nudge(dx: 0, dy: step); return true // up
        case 48: cycleLoupeTheme(reverse: event.modifierFlags.contains(.shift)); return true // Tab
        default:
            // Swallow bare keys so the app's single-key shortcuts (x to swap, h/p/c, the format
            // keys) can't fire mid-pick. Let Command combos through for system shortcuts.
            return !event.modifierFlags.contains(.command)
        }
    }

    /// Steps the live loupe through the available themes (Shift+Tab reverses), so you can
    /// switch styles mid-pick without going into Settings. Persists the choice.
    private func cycleLoupeTheme(reverse: Bool) {
        let themes = LoupeTheme.allCases
        guard let index = themes.firstIndex(of: Defaults[.loupeTheme]) else { return }
        let next = (index + (reverse ? -1 : 1) + themes.count) % themes.count
        Defaults[.loupeTheme] = themes[next]
        // Show/hide the card beside the disc for the new theme, and rebuild the capture
        // filter so a newly-shown card panel is excluded from the magnified image.
        updateCardPanel()
        configuredDisplayID = nil
        requestCapture()
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

    /// Whether the cursor is over one of Pika's own windows (excluding the loupe panels). Used to
    /// fall back to the current colours instead of sampling — and feeding back — Pika's own UI.
    private func isCursorOverAppWindow() -> Bool {
        let loupeNumbers = Set(loupeWindowIDs.map { Int($0) })
        return NSApp.windows.contains { window in
            window.isVisible
                && !loupeNumbers.contains(window.windowNumber)
                && window.frame.contains(currentCursor)
        }
    }

    private func requestCapture() {
        guard isActive else { return } // no captures once the pick has ended
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
        let generation = pickGeneration
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
            // The grab is async: if the pick was cancelled/committed (or a new one began) while
            // it was in flight, this result is stale — discard it so it can't write a colour
            // into a finished pick (the cause of a straggler landing on Escape or a drag).
            guard generation == pickGeneration else { return }
            let cropped = full.cropping(to: region) ?? full
            viewModel.image = cropped
            let pixel = Self.centerPixelColor(of: cropped) ?? viewModel.sampleColor
            // Over Pika's own UI, fall back to the colour the pick started with so sampling
            // doesn't feed the swatch back into itself (and fade the loupe to signal that).
            let overApp = isCursorOverAppWindow()
            viewModel.isOverApp = overApp
            if overApp, let previewOriginal {
                viewModel.sampleColor = previewOriginal
            } else {
                viewModel.sampleColor = pixel
            }
            // Live-preview the sample into the app (footer / swatches track the cursor) once the
            // pick is visible. Not recorded to history (see `previewOriginal`).
            if isActive {
                targetEyedropper?.set(viewModel.sampleColor)
            }
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
        viewModel.colorName = closestColorName(for: viewModel.sampleColor)
    }

    /// Closest colour name for `color`, building the lookup vector on first use.
    private func closestColorName(for color: NSColor) -> String {
        if closestVector == nil {
            colorNames = ColorNamesManager.shared.currentColorNames()
            closestVector = ClosestVector(colorNames.map { $0.color.toRGB8BitArray() })
        }
        guard let closestVector, !colorNames.isEmpty else { return "" }
        let index = closestVector.compare(color)
        return colorNames.indices.contains(index) ? colorNames[index].name : ""
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
    /// Closest-colour name for `comparison`, resolved once per pick (the pair doesn't change).
    @Published var comparisonName: String = ""
    @Published var pixelCount: Int = 15
    /// True while the cursor is over one of Pika's own windows — the loupe fades to signal it
    /// won't sample there (it falls back to the current colours instead).
    @Published var isOverApp: Bool = false

    private let minPixels = 5
    private let maxPixels = 41

    func zoomIn() { pixelCount = max(minPixels, pixelCount - 2) }
    func zoomOut() { pixelCount = min(maxPixels, pixelCount + 2) }
}
