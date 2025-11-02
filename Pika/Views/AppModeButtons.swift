import Defaults
import SwiftUI

struct AppModeButtons: View {
    @Default(.appMode) var appMode
    var width: CGFloat

    var body: some View {
        Button(action: {
            appMode = .menubar
        }, label: {
            AppModeToggleGroup(theme: .menubar)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
        .buttonStyle(AppearanceButtonStyle(
            title: PikaText.textAppMenubarTitle,
            description: PikaText.textAppMenubarDescription,
            selected: appMode == .menubar
        ))
        Button(action: {
            appMode = .regular
        }, label: {
            AppModeToggleGroup(theme: .regular)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
        .buttonStyle(AppearanceButtonStyle(
            title: PikaText.textAppDockTitle,
            description: PikaText.textAppDockDescription,
            selected: appMode == .regular
        ))
    }
}

struct AppModeButtons_Previews: PreviewProvider {
    static var previews: some View {
        AppModeButtons(width: 200)
    }
}
