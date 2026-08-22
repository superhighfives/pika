import Cocoa
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI
#if TARGET_SPARKLE
    import Sparkle
#endif

class AppDelegate: NSObject, NSApplicationDelegate {
    /// The live app delegate. `NSApp.delegate` cannot be relied on here: under
    /// `@NSApplicationDelegateAdaptor`, AppKit's `NSApp.delegate` is SwiftUI's own
    /// forwarding wrapper (`SwiftUI.AppDelegate`), so `NSApp.delegate as? AppDelegate`
    /// is always `nil` and any call chained off it silently no-ops. Capture the real
    /// instance on launch and reach it through here instead.
    weak static var shared: AppDelegate?

    var eyedroppers: Eyedroppers!

    let notificationCenter = NotificationCenter.default
    let windowCoordinator = WindowCoordinator()
    let statusBarController = StatusBarController()

    func setupAppMode() {
        var currentMode = Defaults[.appMode].activationPolicy
        NSApp.setActivationPolicy(currentMode)
        Defaults.observe(.appMode) { [weak self] change in
            guard let self = self else { return }
            let newMode = change.newValue.activationPolicy
            if newMode != currentMode {
                currentMode = newMode
                NSApp.setActivationPolicy(newMode)
                NSApp.activate(ignoringOtherApps: true)
                if change.newValue == .regular {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        NSApp.unhide(self)
                        if let window = NSApp.windows.first {
                            if window.canBecomeKey {
                                window.makeKeyAndOrderFront(self)
                            }
                            window.setIsVisible(true)
                        }
                    }
                }
            }
            if change.oldValue != change.newValue {
                if change.newValue.usesPopover {
                    self.windowCoordinator.hideMainWindow()
                    self.windowCoordinator.removeMainWindowContent()
                    self.statusBarController.attachPopover(
                        rootView: PopoverContentView(eyedroppers: self.eyedroppers)
                    )
                } else if change.oldValue.usesPopover {
                    self.statusBarController.detachPopover()
                    self.windowCoordinator.installMainWindowContent()
                }
            }
        }.tieToLifetime(of: self)
    }

    func applicationWillFinishLaunching(_: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.prohibited)
        NSAppleEventManager.shared().setEventHandler(
            URLSchemeHandler.shared,
            andSelector: #selector(URLSchemeHandler.handle(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_: Notification) {
        LaunchAtLogin.migrateIfNeeded()
        migrateHistoryToPalettes()
        removeUpdatesMenuItemIfNeeded()

        eyedroppers = Eyedroppers()
        setupInterface()
        setupAppMode()
        registerTogglePikaShortcut()
        presentSplashIfNeeded()
        validateColorSpace()
        showPikaIfConfigured()
        registerGlobalKeyMonitor()

        // Refresh the colour-name list from color.pizza (catalogue + selected list) and cache
        // it; the eyedroppers rebuild via `.colorNamesUpdated`. Best-effort — falls back to
        // the bundled default offline.
        ColorNamesManager.shared.updateOnLaunch()
    }

    private func removeUpdatesMenuItemIfNeeded() {
        #if TARGET_MAS
            if let mainMenu = NSApp.mainMenu?.item(withTitle: PikaText.textAppName)?.submenu {
                if let checkForUpdatesMenuItem = mainMenu.item(withTitle: "\(PikaText.textMenuUpdates)…") {
                    mainMenu.removeItem(checkForUpdatesMenuItem)
                }
            }
        #endif
    }

    private func setupInterface() {
        windowCoordinator.setupMainWindow(eyedroppers: eyedroppers)

        statusBarController.setup()
        statusBarController.onToggle = { [weak self] in self?.windowCoordinator.togglePopover() }

        if Defaults[.appMode].usesPopover {
            statusBarController.attachPopover(rootView: PopoverContentView(eyedroppers: eyedroppers))
        } else {
            windowCoordinator.installMainWindowContent()
        }
    }

    private func registerTogglePikaShortcut() {
        KeyboardShortcuts.onKeyUp(for: .togglePika) { [] in
            if Defaults[.viewedSplash] {
                NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
            }
        }
        KeyboardShortcuts.onKeyUp(for: .pickPair) { [] in
            if Defaults[.viewedSplash] {
                NSApp.sendAction(#selector(AppDelegate.triggerPickContrast), to: nil, from: nil)
            }
        }
    }

    /// The splash shows on every launch unless the user ticked its (pre-selected) "Don't show
    /// this again" checkbox — EXCEPT when a new onboarding version hasn't been seen yet, in which
    /// case it shows once for everyone (see `PikaConstants.currentSplashVersion`).
    private var shouldShowSplash: Bool {
        !Defaults[.hideSplashOnLaunch]
            || Defaults[.lastSeenSplashVersion] < PikaConstants.currentSplashVersion
    }

    private func presentSplashIfNeeded() {
        // `viewedSplash` still records the first run so the pick shortcuts stay gated until
        // onboarding is dismissed the first time. `lastSeenSplashVersion` is recorded on
        // dismissal (`closeSplashWindow`), not here — recording it now would make
        // `showPikaIfConfigured` reveal the main window behind the splash.
        if shouldShowSplash {
            openSplashWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func validateColorSpace() {
        if !NSColorSpace.availableColorSpaces(with: .rgb).contains(Defaults[.colorSpace]) {
            Defaults[.colorSpace] = Defaults.Keys.colorSpace.defaultValue
        }
    }

    private func showPikaIfConfigured() {
        // Pika should only ever appear once the splash has been dismissed. When the splash
        // is up, defer the main window until `closeSplashWindow` fires; otherwise show it now.
        guard !shouldShowSplash else { return }
        presentConfiguredPika()
    }

    private func presentConfiguredPika() {
        if Defaults[.alwaysShowOnLaunch], !Defaults[.appMode].usesPopover {
            showPika(self)
        }
    }

    private func registerGlobalKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // History drawer navigation (existing behaviour)
            if Defaults[.historyDrawerVisible] {
                let isInTextField = (NSApp.keyWindow?.firstResponder as? NSResponder)
                    .map { $0 is NSTextView || $0 is NSTextField } ?? false
                if !isInTextField {
                    switch event.keyCode {
                    case 123:
                        self.notificationCenter.post(name: .historyNext, object: self)
                        return nil
                    case 124:
                        self.notificationCenter.post(name: .historyPrevious, object: self)
                        return nil
                    case 51:
                        self.notificationCenter.post(name: .historyDelete, object: self)
                        return nil
                    default:
                        break
                    }
                }
            }

            // In popover mode neither `NSApp.mainMenu.performKeyEquivalent` nor SwiftUI's
            // command-bound `.keyboardShortcut` fire while the popover panel is the key
            // window of an `.accessory` app — only `.keyboardShortcut` bindings attached to
            // views *inside* the popover are reachable. Dispatch the canonical shortcuts
            // (`PikaShortcuts.all`) manually here so popover behaviour matches menubar/dock.
            let isInTextField = (NSApp.keyWindow?.firstResponder as? NSResponder)
                .map { $0 is NSTextView || $0 is NSTextField } ?? false
            if Defaults[.appMode].usesPopover, self.statusBarController.isPopoverShown,
               !isInTextField, let shortcut = PikaShortcuts.match(event)
            {
                NSApp.sendAction(shortcut.action, to: nil, from: nil)
                return nil
            }

            return event
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            if Defaults[.appMode].usesPopover {
                statusBarController.showPopover()
            } else {
                windowCoordinator.pikaWindow.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        true
    }

    // MARK: - Migration

    private func migrateHistoryToPalettes() {
        let existing = Defaults[.colorHistory]
        guard !existing.isEmpty else { return }
        let history = Palette(id: UUID(), name: nil, pairs: existing, createdAt: Date())
        var palettes = Defaults[.palettes]
        if palettes.isEmpty {
            palettes = [history]
        } else {
            palettes[0] = Palette(
                id: palettes[0].id,
                name: palettes[0].name,
                pairs: existing + palettes[0].pairs,
                createdAt: palettes[0].createdAt
            )
        }
        Defaults[.palettes] = palettes
        Defaults[.colorHistory] = []
    }
}

// MARK: - Window forwarding

extension AppDelegate {
    @objc func closeSplashWindow() {
        windowCoordinator.closeSplashWindow()
        // Record that this onboarding version has been seen, so the version gate doesn't
        // re-show it next launch (the user's "Don't show again" choice governs from here).
        Defaults[.lastSeenSplashVersion] = PikaConstants.currentSplashVersion
        // Now that onboarding is dismissed, show Pika if the user has it set to launch shown.
        presentConfiguredPika()
    }

    @objc func togglePopover(_: AnyObject?) { windowCoordinator.togglePopover() }

    @IBAction func openAboutWindow(_: Any?) { windowCoordinator.openAboutWindow() }
    @IBAction func openHelpWindow(_: Any?) { windowCoordinator.openHelpWindow() }
    @IBAction func openPreferencesWindow(_: Any?) { windowCoordinator.openPreferencesWindow() }
    @IBAction func openSplashWindow(_: Any?) { windowCoordinator.openSplashWindow() }
    @IBAction func showPika(_: Any) { windowCoordinator.showPika() }
    @IBAction func hidePika(_: Any) { windowCoordinator.hidePika() }
    @IBAction func showPopover(_: Any) { statusBarController.showPopover() }
}

// MARK: - Notification dispatch

extension AppDelegate {
    @IBAction func triggerPickForeground(_: Any) {
        notificationCenter.post(name: .triggerPickForeground, object: self)
    }

    @IBAction func triggerPickBackground(_: Any) {
        notificationCenter.post(name: .triggerPickBackground, object: self)
    }

    @IBAction func triggerPickContrast(_: Any) {
        notificationCenter.post(name: .triggerPickForeground, object: self, userInfo: ["chain": true])
        notificationCenter.post(name: .triggerPickPair, object: self)
    }

    @IBAction func triggerCopyForeground(_: Any) {
        notificationCenter.post(name: .triggerCopyForeground, object: self)
    }

    @IBAction func triggerCopyBackground(_: Any) {
        notificationCenter.post(name: .triggerCopyBackground, object: self)
    }

    @IBAction func triggerSystemPickerForeground(_: Any) {
        notificationCenter.post(name: .triggerSystemPickerForeground, object: self)
    }

    @IBAction func triggerSystemPickerBackground(_: Any) {
        notificationCenter.post(name: .triggerSystemPickerBackground, object: self)
    }

    @IBAction func triggerToggleHistory(_: Any) {
        notificationCenter.post(name: .toggleHistory, object: self)
    }

    @IBAction func triggerToggleColorPreview(_: Any) {
        notificationCenter.post(name: .toggleColorPreview, object: self)
    }

    @IBAction func triggerToggleCompliance(_: Any) {
        notificationCenter.post(name: .toggleCompliance, object: self)
    }

    @IBAction func triggerHistoryPrevious(_: Any) {
        notificationCenter.post(name: .historyPrevious, object: self)
    }

    @IBAction func triggerHistoryNext(_: Any) {
        notificationCenter.post(name: .historyNext, object: self)
    }

    @IBAction func triggerHistoryDelete(_: Any) {
        notificationCenter.post(name: .historyDelete, object: self)
    }

    @IBAction func triggerSwap(_: Any) {
        notificationCenter.post(name: .triggerSwap, object: self)
    }

    /// The `NSTextView` field editor of whichever `ScrubTextField` is currently being edited, if
    /// any — `ScrubTextField.becomeFirstResponder` makes the field editor (not the field itself)
    /// the window's first responder while editing, so this is the one place both `triggerUndo`
    /// and `triggerRedo` need to check to keep Cmd-Z scoped to "whatever the user is actually
    /// looking at": a value being typed, if one is focused, otherwise colour-pick history.
    private var focusedFieldUndoManager: UndoManager? {
        guard let editor = NSApp.keyWindow?.firstResponder as? NSTextView, editor.isFieldEditor else { return nil }
        return editor.undoManager
    }

    @IBAction func triggerUndo(_: Any) {
        if let manager = focusedFieldUndoManager, manager.canUndo {
            manager.undo()
            return
        }
        notificationCenter.post(name: .triggerUndo, object: self)
        eyedroppers.undo()
    }

    @IBAction func triggerRedo(_: Any) {
        if let manager = focusedFieldUndoManager, manager.canRedo {
            manager.redo()
            return
        }
        notificationCenter.post(name: .triggerRedo, object: self)
        eyedroppers.redo()
    }

    @IBAction func triggerCopyText(_: Any) {
        notificationCenter.post(name: .triggerCopyText, object: self)
    }

    @IBAction func triggerCopyData(_: Any) {
        notificationCenter.post(name: .triggerCopyData, object: self)
    }

    @IBAction func triggerFormatHex(_: Any) {
        notificationCenter.post(name: .triggerFormatHex, object: self)
    }

    @IBAction func triggerFormatRGB(_: Any) {
        notificationCenter.post(name: .triggerFormatRGB, object: self)
    }

    @IBAction func triggerFormatHSB(_: Any) {
        notificationCenter.post(name: .triggerFormatHSB, object: self)
    }

    @IBAction func triggerFormatHSL(_: Any) {
        notificationCenter.post(name: .triggerFormatHSL, object: self)
    }

    @IBAction func triggerFormatOpenGL(_: Any) {
        notificationCenter.post(name: .triggerFormatOpenGL, object: self)
    }

    @IBAction func triggerFormatLAB(_: Any) {
        notificationCenter.post(name: .triggerFormatLAB, object: self)
    }

    @IBAction func triggerFormatOKLCH(_: Any) {
        notificationCenter.post(name: .triggerFormatOKLCH, object: self)
    }
}

// MARK: - App actions

extension AppDelegate {
    #if TARGET_SPARKLE
        @IBAction func updateFeedURL(_: Any) {
            SUUpdater.shared().feedURL = URL(string: PikaConstants.url())
        }

        @IBAction func checkForUpdates(_: Any) {
            SUUpdater.shared().feedURL = URL(string: PikaConstants.url())
            SUUpdater.shared()?.checkForUpdates(self)
        }
    #endif

    #if TARGET_MAS
        @IBAction func checkForUpdates(_: Any) {}
    #endif

    @IBAction func openWebsite(_: Any) {
        NSWorkspace.shared.open(URL(string: PikaConstants.pikaWebsiteURL)!)
    }

    @IBAction func openGitHubIssue(_: Any) {
        NSWorkspace.shared.open(URL(string: PikaConstants.gitHubIssueURL)!)
    }

    @IBAction func terminatePika(_: Any) {
        NSApplication.shared.terminate(self)
    }
}
