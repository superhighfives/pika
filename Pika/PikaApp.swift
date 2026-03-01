import Defaults
import SwiftUI

@main
struct PikaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.appMode) private var appMode
    @Default(.hideMenuBarIcon) private var hideMenuBarIcon
    @Default(.openAsWindow) private var openAsWindow

    var body: some Scene {
        // Read-only binding: visibility is purely derived from preferences.
        // The no-op setter prevents SwiftUI from toggling it independently.
        MenuBarExtra(isInserted: Binding(
            get: { appMode == .menubar && !hideMenuBarIcon && !openAsWindow },
            set: { _ in }
        )) {
            PopoverContentView()
                .environmentObject(appDelegate.eyedroppers)
        } label: {
            Image("StatusBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
