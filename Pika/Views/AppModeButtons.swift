import Defaults
import SwiftUI

struct AppModeButtons: View {
    @Default(.appMode) var appMode
    var width: CGFloat

    var body: some View {
        // TODO: Fix title
        Button(action: {
            appMode = .menubar
        }, label: {
            AppModeToggleGroup(theme: .menubar)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: "Menu Bar",
                description: "Show in menu bar",
                selected: appMode == .menubar
            ))
        // TODO: Fix title
        Button(action: {
            appMode = .regular
        }, label: {
            AppModeToggleGroup(theme: .regular)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: "Dock",
                description: "Show in dock",
                selected: appMode == .regular
            ))
        // TODO: Fix title
        Button(action: {
            appMode = .hidden
        }, label: {
            AppModeToggleGroup(theme: .hidden)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: "Hidden",
                description: "Hide app",
                selected: appMode == .hidden
            ))
    }
}

struct AppModeButtons_Previews: PreviewProvider {
    static var previews: some View {
        AppModeButtons(width: 200)
    }
}
