import SwiftUI

private func send(_ selector: Selector) {
    NSApp.sendAction(selector, to: nil, from: nil)
}

private struct PikaCommands: Commands {
    var body: some Commands {
        // Pika menu items added before the first divider after .appInfo (About Pika).
        CommandGroup(after: .appInfo) {
            Button(PikaText.textMenuShowSplash) { send(#selector(AppDelegate.openSplashWindow)) }
            Button(PikaText.textMenuUpdates) { send(#selector(AppDelegate.checkForUpdates)) }
            Button(PikaText.textMenuPreferences) { send(#selector(AppDelegate.openPreferencesWindow)) }
                .keyboardShortcut(",", modifiers: .command)
        }

        // Replace the SwiftUI default Settings command (we handle Preferences ourselves).
        CommandGroup(replacing: .appSettings) {}

        // Replace the default Undo/Redo group: its stock items send the plain `undo:`/`redo:`
        // responder-chain actions, which AppKit's automatic menu validation disables unless some
        // responder in the chain vends a real `NSUndoManager` — nothing here does, so those items
        // stayed permanently greyed out and Cmd-Z silently did nothing. Explicit actions bound to
        // `triggerUndo`/`triggerRedo` sidestep that validation entirely (same pattern as every
        // other custom menu item below); those methods do their own focus-scoping — deferring to
        // a focused field's own undo manager before falling back to colour-pick history.
        CommandGroup(replacing: .undoRedo) {
            Button(PikaText.textColorUndo) { send(#selector(AppDelegate.triggerUndo)) }
                .keyboardShortcut("z", modifiers: .command)
            Button(PikaText.textColorRedo) { send(#selector(AppDelegate.triggerRedo)) }
                .keyboardShortcut("z", modifiers: [.command, .shift])
        }

        // Pasteboard group hosts the picker / copy / format actions.
        CommandGroup(replacing: .pasteboard) {
            Button(PikaText.textPickForeground + "…") { send(#selector(AppDelegate.triggerPickForeground)) }
                .keyboardShortcut("d", modifiers: .command)
            Button(PikaText.textPickBackground + "…") { send(#selector(AppDelegate.triggerPickBackground)) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            // No key equivalent here: pick-pair is now a global, rebindable shortcut
            // (KeyboardShortcuts.Name.pickPair). A menu accelerator would double-fire
            // with the global hotkey and wouldn't track user rebindings.
            Button(PikaText.textPickPair + "…") { send(#selector(AppDelegate.triggerPickContrast)) }

            Divider()

            Button(PikaText.textColorSystemPickerForeground) { send(#selector(AppDelegate.triggerSystemPickerForeground)) }
                .keyboardShortcut("s", modifiers: .command)
            Button(PikaText.textColorSystemPickerBackground) { send(#selector(AppDelegate.triggerSystemPickerBackground)) }
                .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()

            Button(PikaText.textColorSwapDetail) { send(#selector(AppDelegate.triggerSwap)) }
                .keyboardShortcut("x", modifiers: [])

            Divider()

            Button(PikaText.textCopyForeground) { send(#selector(AppDelegate.triggerCopyForeground)) }
                .keyboardShortcut("c", modifiers: .command)
            Button(PikaText.textCopyBackground) { send(#selector(AppDelegate.triggerCopyBackground)) }
                .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            Button(PikaText.textHistoryToggle) { send(#selector(AppDelegate.triggerToggleHistory)) }
                .keyboardShortcut("h", modifiers: [])
        }

        // Help menu — point at Pika's website + GitHub feedback.
        CommandGroup(replacing: .help) {
            Button(PikaText.textMenuWebsite) { send(#selector(AppDelegate.openWebsite)) }
                .keyboardShortcut("?", modifiers: .command)
            Button(PikaText.textMenuGitHubIssue) { send(#selector(AppDelegate.openGitHubIssue)) }
        }
    }
}

@main
struct PikaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
            .commands { PikaCommands() }
    }
}
