import Cocoa
import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    var pikaWindow: NSWindow!
    var splashWindow: NSWindow!
    var aboutWindow: NSWindow!
    var preferencesWindow: NSWindow!
    var eyedroppers: Eyedroppers!

    var pikaTouchBarController: PikaTouchBarController!
    var splashTouchBarController: SplashTouchBarController!
    var aboutTouchBarController: SplashTouchBarController!

    let notificationCenter = NotificationCenter.default

    func applicationDidFinishLaunching(_: Notification) {
        // Set up status bar and menu
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIcon")
            button.action = #selector(statusBarClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        statusBarMenu = getStatusBarMenu()

        statusBarItem.isVisible = Defaults[.hideMenuBarIcon] == false
        Defaults.observe(.hideMenuBarIcon) { change in
            self.statusBarItem.isVisible = change.newValue == false
        }.tieToLifetime(of: self)

        // Set up eyedroppers
        eyedroppers = Eyedroppers()

        // Define content view
        let contentView = ContentView()
            .environmentObject(eyedroppers)
            .frame(minWidth: 450,
                   idealWidth: 450,
                   maxWidth: 550,
                   minHeight: 200,
                   idealHeight: 220,
                   maxHeight: 360,
                   alignment: .center)

        pikaWindow = PikaWindow.createPrimaryWindow()
        pikaWindow.contentView = NSHostingView(rootView: contentView)
        pikaTouchBarController = PikaTouchBarController(window: pikaWindow)

        // Define global keyboard shortcuts
        KeyboardShortcuts.onKeyUp(for: .togglePika) { [self] in
            if Defaults[.viewedSplash] {
                togglePopover(nil)
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
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            pikaWindow.makeKeyAndOrderFront(self)
        }
        return true
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
            withTitle: NSLocalizedString("menu.about", comment: "About"),
            action: #selector(openAboutWindow(_:)),
            keyEquivalent: ""
        )
        statusBarMenu.addItem(
            withTitle: "\(NSLocalizedString("menu.updates", comment: "Check for updates"))...",
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        statusBarMenu.addItem(
            withTitle: NSLocalizedString("menu.preferences", comment: "Preferences"),
            action: #selector(openPreferencesWindow(_:)),
            keyEquivalent: ""
        )
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(
            withTitle: NSLocalizedString("menu.quit", comment: "Quit Pika"),
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

            // Trigger picker on open
            NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
        }
    }

    @IBAction func openAboutWindow(_: Any?) {
        if aboutWindow == nil {
            aboutWindow = PikaWindow.createSecondaryWindow(
                title: "About",
                size: NSRect(x: 0, y: 0, width: 300, height: 540),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            aboutTouchBarController = SplashTouchBarController(window: aboutWindow)
            aboutWindow.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = PikaWindow.createSecondaryWindow(
                title: "Preferences",
                size: NSRect(x: 0, y: 0, width: 550, height: 480),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            preferencesWindow.contentView = NSHostingView(rootView: PreferencesView())
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openSplashWindow(_: Any?) {
        if splashWindow == nil {
            splashWindow = PikaWindow.createSecondaryWindow(
                title: "Splash",
                size: NSRect(x: 0, y: 0, width: 600, height: 260),
                styleMask: [.titled, .fullSizeContentView]
            )
            if #available(OSX 11.0, *) {
                splashWindow.title = NSLocalizedString("app.name", comment: "Pika")
                splashWindow.titleVisibility = .visible
            }
            splashTouchBarController = SplashTouchBarController(window: splashWindow)
            splashWindow.contentView = NSHostingView(rootView: SplashView().edgesIgnoringSafeArea(.all))
        }
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

    @IBAction func hidePika(_: Any) {
        hideMainWindow()
    }

    @IBAction func showPika(_: Any) {
        pikaWindow.fadeIn(sender: nil, duration: 0.2)
    }

    @IBAction func checkForUpdates(_: Any) {
        SUUpdater.shared().feedURL = URL(string: PikaConstants.url())
        SUUpdater.shared()?.checkForUpdates(self)
    }

    @IBAction func terminatePika(_: Any) {
        NSApplication.shared.terminate(self)
    }
}
