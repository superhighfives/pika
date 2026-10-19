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

    #if TARGET_SPARKLE
        /// Sparkle 2 updater. Created on launch so scheduled update checks start with the app.
        private(set) lazy var updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    #endif

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
        #if TARGET_SPARKLE
            // Sparkle 1 persisted the runtime feed URL to user defaults, where Sparkle 2 would
            // still read it. The feed now comes from `feedURLString(for:)`, so drop the stale copy.
            updaterController.updater.clearFeedURLFromUserDefaults()
        #endif

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

    // KeyboardShortcuts 3.x isolates `onKeyUp(for:action:)` to the main actor, so this
    // registration must run there too. Its only caller, `applicationDidFinishLaunching`,
    // is already main-actor isolated.
    @MainActor
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

            if self.handleCommandKey(event) { return nil }

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

    /// ⌘-key handling the menu bar can't provide. Returns true when `event` was consumed.
    private func handleCommandKey(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              let key = event.charactersIgnoringModifiers?.lowercased() else { return false }

        // ⌘N: a hidden alias for Window → "Show Pika" (⌘0). SwiftUI can't hide a menu
        // item, so it's matched here rather than given a second visible entry.
        if key == "n" {
            showMainInterface(self)
            return true
        }

        // `PikaCommands` replaces the standard pasteboard menu group, so a focused field
        // never receives cut/copy/paste/select-all key equivalents — pasting `#AABBCC`
        // into a colour value silently did nothing (#269). Route them to the field editor.
        guard let editor = NSApp.keyWindow?.firstResponder as? NSText else { return false }
        switch key {
        case "v": editor.paste(nil)
        case "x": editor.cut(nil)
        case "c": editor.copy(nil)
        case "a": editor.selectAll(nil)
        default: return false
        }
        return true
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if Defaults[.appMode].usesPopover {
            if !hasVisibleWindows { statusBarController.showPopover() }
        } else if !windowCoordinator.pikaWindow.isVisible {
            // Don't trust `hasVisibleWindows` here: Pika's auxiliary windows (the border
            // window, pick overlays) can count as visible while the main window is closed,
            // which left a Dock click with no way back to Pika (#268).
            showPika(self)
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
        // Outside popover mode, the coordinator reveals the main window once the splash fades
        // out whatever `alwaysShowOnLaunch` says (see `WindowCoordinator.startMainWindow`), so a
        // new user always lands on Pika. With `alwaysShowOnLaunch` on, this also shows and
        // activates it straight away rather than after the fade.
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

    /// Bring Pika back however it's configured to appear — the main window, or the popover
    /// in popover mode. Backs the Window → "Show Pika" menu item (⌘0) and the ⌘N alias.
    @IBAction func showMainInterface(_: Any) {
        if Defaults[.appMode].usesPopover {
            statusBarController.showPopover()
        } else {
            showPika(self)
        }
    }
}

// MARK: - App actions

extension AppDelegate {
    #if TARGET_SPARKLE
        @IBAction func checkForUpdates(_ sender: Any) {
            updaterController.checkForUpdates(sender)
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

// MARK: - Updates

#if TARGET_SPARKLE
    extension AppDelegate: SPUUpdaterDelegate {
        /// Sparkle asks for the feed on every check, so the beta toggle takes effect immediately.
        func feedURLString(for _: SPUUpdater) -> String? {
            PikaConstants.url()
        }
    }
#endif
