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
                .padding(20.0)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: appMode == .menubar
            ))

        Button(action: {
            appMode = .regular
        }, label: {
            AppModeToggleGroup(theme: .regular)
                .padding(20.0)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: appMode == .regular
            ))

        Button(action: {
            appMode = .hidden
        }, label: {
            AppModeToggleGroup(theme: .hidden)
                .padding(20.0)
                .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
        })
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: appMode == .hidden
            ))
    }
}

struct AppModeButtons_Previews: PreviewProvider {
    static var previews: some View {
        AppModeButtons(width: 200)
    }
}
