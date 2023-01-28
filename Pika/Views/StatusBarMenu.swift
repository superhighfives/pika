import Cocoa
import Foundation

func getStatusBarMenu(delegate: NSMenuDelegate) -> NSMenu {
    let statusBarMenu = NSMenu(title: "Status Bar Menu")
    statusBarMenu.delegate = delegate
    statusBarMenu.addItem(
        withTitle: PikaText.textMenuAbout,
        action: #selector(AppDelegate.openAboutWindow),
        keyEquivalent: ""
    )

    statusBarMenu.addItem(
        withTitle: "\(PikaText.textMenuUpdates)...",
        action: #selector(AppDelegate.checkForUpdates),
        keyEquivalent: ""
    )

    statusBarMenu.addItem(
        withTitle: PikaText.textMenuGitHubIssue,
        action: #selector(AppDelegate.openGitHubIssue),
        keyEquivalent: ""
    )

    let preferences = NSMenuItem(
        title: PikaText.textMenuPreferences,
        action: #selector(AppDelegate.openPreferencesWindow),
        keyEquivalent: ","
    )
    preferences.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
    statusBarMenu.addItem(preferences)

    statusBarMenu.addItem(NSMenuItem.separator())
    statusBarMenu.addItem(
        withTitle: PikaText.textMenuQuit,
        action: #selector(AppDelegate.terminatePika),
        keyEquivalent: ""
    )

    return statusBarMenu
}
