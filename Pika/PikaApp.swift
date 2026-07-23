import SwiftUI

private func send(_ selector: Selector) {
    NSApp.sendAction(selector, to: nil, from: nil)
}

private struct PikaCommands: Commands {
    var body: some Commands {
        // Pika menu items added before the first divider after .appInfo (About Pika).
        CommandGroup(after: .appInfo) {
            Button(PikaText.textMenuUpdates) { send(#selector(AppDelegate.checkForUpdates)) }
            Button(PikaText.textMenuPreferences) { send(#selector(AppDelegate.openPreferencesWindow)) }
                .keyboardShortcut(",", modifiers: .command)
        }

        // Replace the SwiftUI default Settings command (we handle Preferences ourselves).
        CommandGroup(replacing: .appSettings) {}

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
