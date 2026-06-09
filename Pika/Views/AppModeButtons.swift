import Defaults
import SwiftUI

struct AppModeButtons: View {
    @Default(.appMode) var appMode

    var body: some View {
        Button(action: {
            appMode = .menubar
        }, label: {
            AppModeToggleGroup(theme: .menubar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .buttonStyle(AppearanceButtonStyle(
            title: PikaText.textAppMenubarTitle,
            description: PikaText.textAppMenubarDescription,
            selected: appMode == .menubar,
        ))
        Button(action: {
            appMode = .regular
        }, label: {
            AppModeToggleGroup(theme: .regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .buttonStyle(AppearanceButtonStyle(
            title: PikaText.textAppDockTitle,
            description: PikaText.textAppDockDescription,
            selected: appMode == .regular,
        ))
        Button(action: {
            appMode = .menubarPopover
        }, label: {
            AppModeToggleGroup(theme: .menubarPopover)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .buttonStyle(AppearanceButtonStyle(
            title: PikaText.textAppMenubarPopoverTitle,
            description: PikaText.textAppMenubarPopoverDescription,
            selected: appMode == .menubarPopover,
        ))
    }
}

struct AppModeButtons_Previews: PreviewProvider {
    static var previews: some View {
        AppModeButtons()
    }
}
