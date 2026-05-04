import Defaults
import SwiftUI

@main
struct PikaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.appMode) var appMode

    var body: some Scene {
        Settings { EmptyView() }

        MenuBarExtra(isInserted: .constant(appMode == .menubarPopover)) {
            PopoverContentView(appDelegate: appDelegate)
        } label: {
            Image("StatusBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}
