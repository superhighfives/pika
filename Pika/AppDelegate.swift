import Cocoa
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI
#if TARGET_SPARKLE
    import Sparkle
#endif

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var eyedroppers: Eyedroppers!

    let notificationCenter = NotificationCenter.default
    let windowCoordinator = WindowCoordinator()
    let statusBarController = StatusBarController()

    func setupAppMode() {
        var currentMode = Defaults[.appMode] == .regular
            ? NSApplication.ActivationPolicy.regular
            : NSApplication.ActivationPolicy.accessory
        NSApp.setActivationPolicy(currentMode)
        Defaults.observe(.appMode) { change in
            let newMode = change.newValue == .regular
                ? NSApplication.ActivationPolicy.regular
                : NSApplication.ActivationPolicy.accessory
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
        }.tieToLifetime(of: self)
    }

    func applicationWillFinishLaunching(_: Notification) {
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

        #if TARGET_MAS
            if let mainMenu = NSApp.mainMenu?.item(withTitle: PikaText.textAppName)?.submenu {
                if let checkForUpdatesMenuItem = mainMenu.item(withTitle: "\(PikaText.textMenuUpdates)…") {
                    mainMenu.removeItem(checkForUpdatesMenuItem)
                }
            }
        #endif

        setupAppMode()

        statusBarController.setup()
        statusBarController.onToggle = { [weak self] in self?.windowCoordinator.togglePopover() }

        eyedroppers = Eyedroppers()

        windowCoordinator.setupMainWindow(eyedroppers: eyedroppers)

        KeyboardShortcuts.onKeyUp(for: .togglePika) { [] in
            if Defaults[.viewedSplash] {
                NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
            }
        }

        if !Defaults[.viewedSplash] {
            openSplashWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        if !NSColorSpace.availableColorSpaces(with: .rgb).contains(Defaults[.colorSpace]) {
            Defaults[.colorSpace] = Defaults.Keys.colorSpace.defaultValue
        }

        if Defaults[.alwaysShowOnLaunch] {
            showPika(self)
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard Defaults[.historyDrawerVisible] else { return event }
            switch event.keyCode {
            case 123: // left arrow
                self.notificationCenter.post(name: .historyNext, object: self)
                return nil
            case 124: // right arrow
                self.notificationCenter.post(name: .historyPrevious, object: self)
                return nil
            case 51: // delete key
                self.notificationCenter.post(name: .historyDelete, object: self)
                return nil
            default:
                return event
            }
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            windowCoordinator.pikaWindow.makeKeyAndOrderFront(self)
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
        Defaults[.palettes] = [history]
        Defaults[.colorHistory] = []
    }

    // MARK: - Window forwarding

    @objc func closeSplashWindow() { windowCoordinator.closeSplashWindow() }
    @objc func togglePopover(_: AnyObject?) { windowCoordinator.togglePopover() }

    @IBAction func openAboutWindow(_: Any?) { windowCoordinator.openAboutWindow() }
    @IBAction func openHelpWindow(_: Any?) { windowCoordinator.openHelpWindow() }
    @IBAction func openPreferencesWindow(_: Any?) { windowCoordinator.openPreferencesWindow() }
    @IBAction func openSplashWindow(_: Any?) { windowCoordinator.openSplashWindow() }
    @IBAction func showPika(_: Any) { windowCoordinator.showPika() }
    @IBAction func hidePika(_: Any) { windowCoordinator.hidePika() }

    // MARK: - Notification dispatch

    @IBAction func triggerPickForeground(_: Any) {
        notificationCenter.post(name: .triggerPickForeground, object: self)
    }

    @IBAction func triggerPickBackground(_: Any) {
        notificationCenter.post(name: .triggerPickBackground, object: self)
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

    @IBAction func triggerUndo(_: Any) {
        notificationCenter.post(name: .triggerUndo, object: self)
        eyedroppers.undo()
    }

    @IBAction func triggerRedo(_: Any) {
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

    // MARK: - App actions

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
