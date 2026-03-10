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

    private func menuItem(
        title: String,
        action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "Status Bar Menu")
        menu.delegate = self

        menu.addItem(menuItem(title: "\(PikaText.textPickForeground)...",
                              action: #selector(AppDelegate.triggerPickForeground),
                              key: "d"))
        menu.addItem(menuItem(title: "\(PikaText.textPickBackground)...",
                              action: #selector(AppDelegate.triggerPickBackground),
                              key: "d", modifiers: [.command, .shift]))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(menuItem(title: PikaText.textCopyForeground,
                              action: #selector(AppDelegate.triggerCopyForeground),
                              key: "c"))
        menu.addItem(menuItem(title: PikaText.textCopyBackground,
                              action: #selector(AppDelegate.triggerCopyBackground),
                              key: "c", modifiers: [.command, .shift]))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(menuItem(title: PikaText.textColorSystemPickerForeground,
                              action: #selector(AppDelegate.triggerSystemPickerForeground),
                              key: "s"))
        menu.addItem(menuItem(title: PikaText.textColorSystemPickerBackground,
                              action: #selector(AppDelegate.triggerSystemPickerBackground),
                              key: "s", modifiers: [.command, .shift]))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(menuItem(title: PikaText.textColorSwapDetail,
                              action: #selector(AppDelegate.triggerSwap),
                              key: "x", modifiers: []))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(menuItem(title: PikaText.textMenuAbout,
                              action: #selector(AppDelegate.openAboutWindow),
                              key: ""))
        menu.addItem(menuItem(title: "\(PikaText.textMenuUpdates)...",
                              action: #selector(AppDelegate.checkForUpdates),
                              key: ""))
        menu.addItem(menuItem(title: PikaText.textMenuGitHubIssue,
                              action: #selector(AppDelegate.openGitHubIssue),
                              key: ""))
        menu.addItem(menuItem(title: "\(PikaText.textMenuPreferences)...",
                              action: #selector(AppDelegate.openPreferencesWindow),
                              key: ","))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(menuItem(title: PikaText.textMenuQuit,
                              action: #selector(AppDelegate.terminatePika),
                              key: "q"))

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
