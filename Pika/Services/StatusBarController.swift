import Cocoa
import Defaults

/// Owns the status bar item — setup, visibility, and click handling.
/// Calls `onToggle` when the user left-clicks the icon.
class StatusBarController: NSObject, NSMenuDelegate {
    private var statusBarItem: NSStatusItem!
    private var statusBarMenu: NSMenu!

    /// Called when the user left-clicks the status bar icon.
    var onToggle: (() -> Void)?

    func setup() {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIcon")
            button.target = self
            button.action = #selector(statusBarClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        statusBarMenu = buildMenu()

        statusBarItem.isVisible = Defaults[.hideMenuBarIcon] == false && Defaults[.appMode] == .menubar

        Defaults.observe(.hideMenuBarIcon) { [weak self] change in
            self?.statusBarItem.isVisible = change.newValue == false && Defaults[.appMode] == .menubar
        }.tieToLifetime(of: self)

        Defaults.observe(.appMode) { [weak self] change in
            self?.statusBarItem.isVisible = Defaults[.hideMenuBarIcon] == false && change.newValue == .menubar
        }.tieToLifetime(of: self)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "Status Bar Menu")
        menu.delegate = self

        menu.addItem(
            withTitle: PikaText.textMenuAbout,
            action: #selector(AppDelegate.openAboutWindow),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: "\(PikaText.textMenuUpdates)...",
            action: #selector(AppDelegate.checkForUpdates),
            keyEquivalent: ""
        )
        menu.addItem(
            withTitle: PikaText.textMenuGitHubIssue,
            action: #selector(AppDelegate.openGitHubIssue),
            keyEquivalent: ""
        )

        let preferences = NSMenuItem(
            title: "\(PikaText.textMenuPreferences)...",
            action: #selector(AppDelegate.openPreferencesWindow),
            keyEquivalent: ","
        )
        preferences.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        menu.addItem(preferences)

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(
            title: PikaText.textMenuQuit,
            action: #selector(AppDelegate.terminatePika),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = .command
        menu.addItem(quit)

        return menu
    }

    @objc func statusBarClicked(sender _: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event != nil, event!.type == NSEvent.EventType.rightMouseUp || event!.modifierFlags.contains(.control) {
            statusBarItem.menu = statusBarMenu
            statusBarItem.button?.performClick(nil)
        } else {
            onToggle?()
        }
    }

    func menuDidClose(_: NSMenu) {
        statusBarItem.menu = nil
    }
}
