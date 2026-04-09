import Cocoa
import Defaults
import SwiftUI

/// Owns all secondary window lifecycle — creation, presentation, and visibility.
/// The primary Pika window is created here and exposed for `applicationShouldHandleReopen`.
class WindowCoordinator: NSObject {
    weak var eyedroppers: Eyedroppers?

    private(set) var pikaWindow: NSWindow!
    private var splashWindow: NSWindow!
    private var aboutWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var preferencesWindow: NSWindow?

    private var pikaTouchBarController: PikaTouchBarController!
    private var splashTouchBarController: SplashTouchBarController?
    private var aboutTouchBarController: SplashTouchBarController?

    private let notificationCenter = NotificationCenter.default

    func setupMainWindow(eyedroppers: Eyedroppers) {
        self.eyedroppers = eyedroppers

        let contentView = ContentView()
            .environmentObject(eyedroppers)
            .frame(minWidth: 480,
                   idealWidth: 480,
                   maxWidth: 650,
                   minHeight: 280,
                   idealHeight: 280,
                   maxHeight: 400,
                   alignment: .center)

        pikaWindow = PikaWindow.createPrimaryWindow()
        pikaWindow.contentView = NSHostingView(rootView: contentView)
        pikaTouchBarController = PikaTouchBarController(window: pikaWindow)
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

    func closeSplashWindow() {
        splashWindow.fadeOut(sender: nil, duration: 0.25, closeSelector: .close, completionHandler: startMainWindow)
    }

    func togglePopover() {
        if pikaWindow.isVisible {
            hideMainWindow()
        } else {
            showMainWindow()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showPika() {
        if pikaWindow.isVisible {
            pikaWindow.makeKeyAndOrderFront(nil)
        } else {
            pikaWindow.fadeIn(sender: nil, duration: 0.2)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePika() {
        hideMainWindow()
    }

    func openAboutWindow() {
        if aboutWindow == nil {
            let view = NSHostingView(rootView: AboutView().edgesIgnoringSafeArea(.all))
            view.frame = CGRect(x: 0, y: 0, width: 400, height: 0)
            aboutWindow = PikaWindow.createSecondaryWindow(
                title: "About",
                size: NSRect(x: 0, y: 0, width: 400, height: view.fittingSize.height),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
            )
            aboutWindow?.titlebarAppearsTransparent = true
            aboutWindow?.contentView = view
        }
        aboutTouchBarController = SplashTouchBarController(window: aboutWindow!)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    func openHelpWindow() {
        if helpWindow == nil {
            let rootView = HelpView()
                .frame(minWidth: 440, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            let view = NSHostingView(rootView: rootView)
            helpWindow = PikaWindow.createSecondaryWindow(
                title: "Help",
                size: NSRect(x: 0, y: 0, width: 550, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            )
            helpWindow?.minSize = NSSize(width: 440, height: 400)
            helpWindow?.contentMinSize = NSSize(width: 440, height: 400)
            helpWindow?.contentView = view
        }
        helpWindow?.makeKeyAndOrderFront(nil)
    }

    func openPreferencesWindow() {
        if preferencesWindow == nil, let eyedroppers {
            let rootView = PreferencesView()
                .frame(minWidth: 580, maxWidth: 580, minHeight: 400, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .environmentObject(eyedroppers)
            let view = NSHostingView(rootView: rootView)
            preferencesWindow = PikaWindow.createSecondaryWindow(
                title: "Preferences",
                size: NSRect(x: 0, y: 0, width: 580, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            )
            preferencesWindow?.minSize = NSSize(width: 580, height: 400)
            preferencesWindow?.maxSize = NSSize(width: 580, height: CGFloat.greatestFiniteMagnitude)
            preferencesWindow?.contentMinSize = NSSize(width: 580, height: 400)
            preferencesWindow?.contentView = view
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        preferencesWindow?.makeFirstResponder(nil)
        notificationCenter.post(name: .triggerPreferences, object: self)
    }

    func openSplashWindow() {
        splashWindow = PikaWindow.createSecondaryWindow(
            title: PikaText.textAppName,
            size: NSRect(x: 0, y: 0, width: 650, height: 380),
            styleMask: [.titled, .fullSizeContentView]
        )
        splashWindow.titlebarAppearsTransparent = true
        splashTouchBarController = SplashTouchBarController(window: splashWindow)
        splashWindow.contentView = NSHostingView(rootView: SplashView().edgesIgnoringSafeArea(.all))
        splashWindow.fadeIn(nil)
    }
}
