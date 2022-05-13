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
    var windowManager: WindowManager!

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

        // Set up window manager
        windowManager = WindowManager()

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
            withTitle: PikaText.textMenuAbout,
            action: #selector(openAboutWindow(_:)),
            keyEquivalent: ""
        )
        statusBarMenu.addItem(
            withTitle: "\(PikaText.textMenuUpdates)...",
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )

        let preferences = NSMenuItem(
            title: PikaText.textMenuPreferences,
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
            aboutWindow = PikaWindow.createSecondaryWindow(
                title: "About",
                size: NSRect(x: 0, y: 0, width: 340, height: 610),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            aboutTouchBarController = SplashTouchBarController(window: aboutWindow)
            aboutWindow.contentView = NSHostingView(rootView: AboutView().edgesIgnoringSafeArea(.all))
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            let view = NSHostingView(rootView: PreferencesView()
                .edgesIgnoringSafeArea(.all)
                .frame(minWidth: 750, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .environmentObject(eyedroppers)
                .environmentObject(windowManager))
            preferencesWindow = PikaWindow.createSecondaryWindow(
                title: "Preferences",
                size: NSRect(x: 0, y: 0, width: 750, height: view.fittingSize.height),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )

            let toolbarHeight: CGFloat = preferencesWindow.frame.height - preferencesWindow.contentLayoutRect.height
            windowManager.toolbarPadding = toolbarHeight

            preferencesWindow.contentView = view
        }

        preferencesWindow.makeKeyAndOrderFront(nil)
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerPreferences), object: self)
    }

    @IBAction func openSplashWindow(_: Any?) {
        if splashWindow == nil {
            splashWindow = PikaWindow.createSecondaryWindow(
                title: "Splash",
                size: NSRect(x: 0, y: 0, width: 650, height: 260),
                styleMask: [.titled, .fullSizeContentView]
            )
            if #available(OSX 11.0, *) {
                splashWindow.title = PikaText.textAppName
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

    @IBAction func triggerSwap(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerSwap), object: self)
    }

    @IBAction func triggerCopyText(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyText), object: self)
    }

    @IBAction func triggerCopyData(_: Any) {
        notificationCenter.post(name: Notification.Name(PikaConstants.ncTriggerCopyData), object: self)
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

    @IBAction func checkForUpdates(_: Any) {
        SUUpdater.shared().feedURL = URL(string: PikaConstants.url())
        SUUpdater.shared()?.checkForUpdates(self)
    }

    @IBAction func terminatePika(_: Any) {
        NSApplication.shared.terminate(self)
    }
}
