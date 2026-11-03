import Defaults
import SwiftUI

struct MenuGroup<Content>: View where Content: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Menu(title) {
            content()
        }
    }
}

struct NavigationMenuItems: View {
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Default(.historyDrawerVisible) var historyDrawerVisible

    private var exportLabel: String {
        guard historyDrawerVisible else { return PikaText.textHistoryExport }
        let idx = activePaletteIndex
        if idx > 0, idx < palettes.count, palettes[idx].name != nil {
            return PikaText.textPaletteExport
        }
        return PikaText.textHistoryExport
    }

    private func send(_ action: Selector) {
        NSApp.sendAction(action, to: nil, from: nil)
    }

    var body: some View {
        Button("\(PikaText.textPickForeground)...") { send(#selector(AppDelegate.triggerPickForeground)) }
        Button("\(PikaText.textPickBackground)...") { send(#selector(AppDelegate.triggerPickBackground)) }

        MenuGroup(title: PikaText.textColorCopy) {
            Button(PikaText.textColorForeground) { send(#selector(AppDelegate.triggerCopyForeground)) }
            Button(PikaText.textColorBackground) { send(#selector(AppDelegate.triggerCopyBackground)) }
            Divider()
            Button(PikaText.textMenuCopyAllAsText) { send(#selector(AppDelegate.triggerCopyText)) }
            Button(PikaText.textMenuCopyAllAsJSON) { send(#selector(AppDelegate.triggerCopyData)) }
        }

        MenuGroup(title: PikaText.textColorSystemPicker) {
            Button(PikaText.textColorForeground) { send(#selector(AppDelegate.triggerSystemPickerForeground)) }
            Button(PikaText.textColorBackground) { send(#selector(AppDelegate.triggerSystemPickerBackground)) }
        }

        Divider()

        Button(PikaText.textColorSwapDetail) { send(#selector(AppDelegate.triggerSwap)) }
        Button(PikaText.textColorUndo) { send(#selector(AppDelegate.triggerUndo)) }
        Button(PikaText.textColorRedo) { send(#selector(AppDelegate.triggerRedo)) }

        Divider()

        MenuGroup(title: PikaText.textViewPalettes) {
            Button(PikaText.textPaletteNew) { NotificationCenter.default.post(name: .savePalette, object: nil) }
            Button(exportLabel) { NotificationCenter.default.post(name: .exportPalette, object: nil) }
        }

        MenuGroup(title: "Pika") {
            Button(PikaText.textMenuAbout) { send(#selector(AppDelegate.openAboutWindow)) }
            Button(PikaText.textMenuHelp) { send(#selector(AppDelegate.openHelpWindow)) }
            Button(PikaText.textMenuShowSplash) { send(#selector(AppDelegate.openSplashWindow)) }
            #if TARGET_SPARKLE
                Button("\(PikaText.textMenuUpdates)...") { send(#selector(AppDelegate.checkForUpdates)) }
            #endif
            Button(PikaText.textMenuGitHubIssue) { send(#selector(AppDelegate.openGitHubIssue)) }
        }

        Button("\(PikaText.textMenuPreferences)...") { send(#selector(AppDelegate.openPreferencesWindow)) }

        Divider()

        Button(PikaText.textMenuQuit) { NSApplication.shared.terminate(nil) }
    }
}

struct NavigationItems_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenuItems()
    }
}
