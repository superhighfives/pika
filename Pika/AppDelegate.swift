import Cocoa
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Sparkle
import SwiftUI

@main
// swiftlint:disable type_body_length
// swiftlint:disable file_length
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    var pikaWindow: NSWindow!
    var splashWindow: NSWindow!
    var aboutWindow: NSWindow!
    var preferencesWindow: NSWindow!
    var eyedroppers: Eyedroppers!

    var undoManager = UndoManager()

    var pikaTouchBarController: PikaTouchBarController!
    var splashTouchBarController: SplashTouchBarController!
    var aboutTouchBarController: SplashTouchBarController!

    let notificationCenter = NotificationCenter.default

    func setupAppMode() {
        NSApp.setActivationPolicy(Defaults[.appMode] == .regular ? .regular : .accessory)
        Defaults.observe(.appMode) { change in
            NSApp.setActivationPolicy(change.newValue == .regular ? .regular : .accessory)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                NSApp.unhide(self)

                if let window = NSApp.windows.first {
                    // Verify window can become key before making it key and moving it to front
                    if window.canBecomeKey {
                        window.makeKeyAndOrderFront(self)
                    }
                    window.setIsVisible(true)
                }

                self.statusBarItem.isVisible = Defaults[.hideMenuBarIcon] == false && change.newValue == .menubar
            }
        }.tieToLifetime(of: self)
    }

    func setupStatusBar() {
        // Set up status bar and menu
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIcon")
            button.action = #selector(statusBarClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        statusBarMenu = getStatusBarMenu()

        statusBarItem.isVisible = Defaults[.hideMenuBarIcon] == false && Defaults[.appMode] == .menubar
        Defaults.observe(.hideMenuBarIcon) { change in
            self.statusBarItem.isVisible = change.newValue == false && Defaults[.appMode] == .menubar
        }.tieToLifetime(of: self)
    }

    func applicationDidFinishLaunching(_: Notification) {
        LaunchAtLogin.migrateIfNeeded()

        #if TARGET_MAS
            if let mainMenu = NSApp.mainMenu?.item(withTitle: PikaText.textAppName)?.submenu {
                if let checkForUpdatesMenuItem = mainMenu.item(withTitle: "\(PikaText.textMenuUpdates)…") {
                    mainMenu.removeItem(checkForUpdatesMenuItem)
                }
            }
        #endif

        setupAppMode()
        setupStatusBar()

        // Set up eyedroppers
        eyedroppers = Eyedroppers()
        eyedroppers.foreground.undoManager = undoManager
        eyedroppers.background.undoManager = undoManager

        // Define content view
        let contentView = ContentView()
            .environmentObject(eyedroppers)
            .frame(minWidth: 450,
                   idealWidth: 450,
                   maxWidth: 550,
                   minHeight: 230,
                   idealHeight: 230,
                   maxHeight: 360,
                   alignment: .center)

        pikaWindow = PikaWindow.createPrimaryWindow()
        pikaWindow.contentView = NSHostingView(rootView: contentView)
        pikaTouchBarController = PikaTouchBarController(window: pikaWindow)

        // Define global keyboard shortcuts
        KeyboardShortcuts.onKeyUp(for: .togglePika) { [] in
            if Defaults[.viewedSplash] {
                NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
            }
        }

        // Open splash window, or main
        if !Defaults[.viewedSplash] {
            openSplashWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        // Configure color space
        if !NSColorSpace.availableColorSpaces(with: .rgb).contains(Defaults[.colorSpace]) {
            Defaults[.colorSpace] = Defaults.Keys.colorSpace.defaultValue
        }

        if Defaults[.alwaysShowOnLaunch] {
            showPika(true)
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            pikaWindow.makeKeyAndOrderFront(self)
        }
        return true
    }

    func applicationWillFinishLaunching(_: Notification) {
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                                          forEventClass: AEEventClass(kInternetEventClass),
                                          andEventID: AEEventID(kAEGetURL))
    }

    // swiftlint:disable cyclomatic_complexity
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent _: NSAppleEventDescriptor) {
        if let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue {
            let url = URL(string: urlString)
            guard url != nil, let scheme = url!.scheme, let action = url!.host else {
                // some error
                return
            }

            var list = url!.pathComponents.dropFirst()
            let task = list.popFirst()
            let colorFormat = list.popFirst()

            if scheme.caseInsensitiveCompare("pika") == .orderedSame {
                if colorFormat != nil {
                    if let format = ColorFormat.withLabel(colorFormat!) {
                        Defaults[.colorFormat] = format
                    }
                }

                if action == "format" {
                    if let format = ColorFormat.withLabel(task!) {
                        Defaults[.colorFormat] = format
                    }
                }

                if action == "pick" {
                    if task == "foreground" {
                        NSApp.sendAction(#selector(AppDelegate.triggerPickForeground(_:)), to: nil, from: nil)
                    }

                    if task == "background" {
                        NSApp.sendAction(#selector(AppDelegate.triggerPickBackground(_:)), to: nil, from: nil)
                    }
                }

                if action == "system" {
                    if task == "foreground" {
                        NSApp.sendAction(#selector(AppDelegate.triggerSystemPickerForeground(_:)), to: nil, from: nil)
                    }

                    if task == "background" {
                        NSApp.sendAction(#selector(AppDelegate.triggerSystemPickerBackground(_:)), to: nil, from: nil)
                    }
                }

                if action == "copy", task == "foreground" {
                    NSApp.sendAction(#selector(AppDelegate.triggerCopyForeground(_:)), to: nil, from: nil)
                }

                if action == "copy", task == "background" {
                    NSApp.sendAction(#selector(AppDelegate.triggerCopyBackground(_:)), to: nil, from: nil)
                }

                if action == "copy", task == "text" {
                    NSApp.sendAction(#selector(AppDelegate.triggerCopyText(_:)), to: nil, from: nil)
                }

                if action == "copy", task == "json" {
                    NSApp.sendAction(#selector(AppDelegate.triggerCopyData(_:)), to: nil, from: nil)
                }

                if action == "swap" {
                    NSApp.sendAction(#selector(AppDelegate.triggerSwap(_:)), to: nil, from: nil)
                }

                if action == "undo" {
                    NSApp.sendAction(#selector(AppDelegate.triggerUndo(_:)), to: nil, from: nil)
                }

                if action == "redo" {
                    NSApp.sendAction(#selector(AppDelegate.triggerRedo(_:)), to: nil, from: nil)
                }
            }
        }
    }

    func startMainWindow() {
        if !pikaWindow.isVisible {
            pikaWindow.fadeIn(nil)
        }
        Defaults[.viewedSplash] = true
    }

    func showMainWindow() {
        pikaWindow.makeKeyAndOrderFront(nil)
    }

    func hideMainWindow() {
        pikaWindow.orderOut(nil)
    }

    @objc func closeSplashWindow() {
        splashWindow.fadeOut(sender: nil, duration: 0.25, closeSelector: .close, completionHandler: startMainWindow)
    }

    func getStatusBarMenu() -> NSMenu {
        statusBarMenu = NSMenu(title: "Status Bar Menu")
        statusBarMenu.delegate = self
        statusBarMenu.addItem(
            withTitle: PikaText.textMenuAbout,
            action: #selector(openAboutWindow(_:)),
            keyEquivalent: ""
        )

        statusBarMenu.addItem(
            withTitle: "\(PikaText.textMenuUpdates)...",
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )

        statusBarMenu.addItem(
            withTitle: PikaText.textMenuGitHubIssue,
            action: #selector(openGitHubIssue(_:)),
            keyEquivalent: ""
        )

        let preferences = NSMenuItem(
            title: "\(PikaText.textMenuPreferences)...",
            action: #selector(openPreferencesWindow(_:)),
            keyEquivalent: ","
        )
        preferences.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        statusBarMenu.addItem(preferences)

        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(
            withTitle: PikaText.textMenuQuit,
            action: #selector(terminatePika(_:)),
            keyEquivalent: ""
        )

        return statusBarMenu
    }

    @objc func statusBarClicked(sender _: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event != nil, event!.type == NSEvent.EventType.rightMouseUp || event!.modifierFlags.contains(.control) {
            statusBarItem.menu = statusBarMenu
            statusBarItem.button?.performClick(nil)
        } else {
            togglePopover(nil)
        }
    }

    @objc func menuDidClose(_: NSMenu) {
        statusBarItem.menu = nil
    }

    @objc func togglePopover(_: AnyObject?) {
        if pikaWindow.isVisible {
            hideMainWindow()
        } else {
            showMainWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @IBAction func openAboutWindow(_: Any?) {
        if aboutWindow == nil {
            let view = NSHostingView(rootView: AboutView().edgesIgnoringSafeArea(.all))
            aboutWindow = PikaWindow.createSecondaryWindow(
                title: "About",
                size: NSRect(x: 0, y: 0, width: 750, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            aboutWindow.contentView = view
        }
        aboutTouchBarController = SplashTouchBarController(window: aboutWindow)
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            let view = NSHostingView(rootView: PreferencesView()
                .edgesIgnoringSafeArea(.all)
                .frame(minWidth: 750,
                       maxWidth: .infinity,
                       minHeight: 0,
                       maxHeight: 750,
                       alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .environmentObject(eyedroppers))

            preferencesWindow = PikaWindow.createSecondaryWindow(
                title: "Preferences",
                size: NSRect(x: 0, y: 0, width: 750, height: 750),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                maxHeight: 750
            )
            preferencesWindow.contentView = view
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
        preferencesWindow.makeFirstResponder(nil)
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerPreferences), object: self)
    }

    @IBAction func openSplashWindow(_: Any?) {
        splashWindow = PikaWindow.createSecondaryWindow(
            title: "Splash",
            size: NSRect(x: 0, y: 0, width: 650, height: 380),
            styleMask: [.titled, .fullSizeContentView]
        )
        if #available(OSX 11.0, *) {
            splashWindow.title = PikaText.textAppName
            splashWindow.titleVisibility = .visible
        }
        splashTouchBarController = SplashTouchBarController(window: splashWindow)
        splashWindow.contentView = NSHostingView(rootView: SplashView().edgesIgnoringSafeArea(.all))

        splashWindow.fadeIn(nil)
    }

    @IBAction func triggerPickForeground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerPickForeground), object: self)
    }

    @IBAction func triggerPickBackground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerPickBackground), object: self)
    }

    @IBAction func triggerCopyForeground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyForeground), object: self)
    }

    @IBAction func triggerCopyBackground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyBackground), object: self)
    }

    @IBAction func triggerSystemPickerForeground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerSystemPickerForeground), object: self)
    }

    @IBAction func triggerSystemPickerBackground(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerSystemPickerBackground), object: self)
    }

    @IBAction func triggerSwap(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerSwap), object: self)
    }

    @IBAction func triggerUndo(_: Any) {
        undoManager.undo()
    }

    @IBAction func triggerRedo(_: Any) {
        undoManager.redo()
    }

    @IBAction func triggerCopyText(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyText), object: self)
    }

    @IBAction func triggerCopyData(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyData), object: self)
    }

    @IBAction func triggerFormatHex(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerFormatHex), object: self)
    }

    @IBAction func triggerFormatRGB(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerFormatRGB), object: self)
    }

    @IBAction func triggerFormatHSB(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerFormatHSB), object: self)
    }

    @IBAction func triggerFormatHSL(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerFormatHSL), object: self)
    }

    @IBAction func triggerFormatOpenGL(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerFormatOpenGL), object: self)
    }

    @IBAction func hidePika(_: Any) {
        hideMainWindow()
    }

    @IBAction func showPika(_: Any) {
        if pikaWindow.isVisible {
            pikaWindow.makeKeyAndOrderFront(self)
        } else {
            pikaWindow.fadeIn(sender: nil, duration: 0.2)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

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
        @IBAction func checkForUpdates(_: Any) {
            print("Check for updates...")
            // Task {
            //     do {
            //         let api = LookUpAPI()
            //         if let available = try await api.getLatestAvailableVersion(
            //             for: "YOUR_ACTUAL_APP_ID"
            //         ) {
            //             // Handle the version info here
            //             print("Latest version available: \(available)")
            //         } else {
            //             print("Lookup failed")
            //         }
            //     } catch {
            //         print("Error checking for updates: \(error)")
            //     }
            // }
        }
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
