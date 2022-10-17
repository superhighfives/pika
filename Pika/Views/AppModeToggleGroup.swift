import Defaults
import SwiftUI

struct AppModeToggleGroup: View {
    var theme: Themes

    enum Themes: String, Codable, CaseIterable {
        case menubar
        case regular
        case hidden
    }

    var body: some View {
        if theme == .menubar {
            Image("menubar")
        }

        if theme == .regular {
            Image("dock")
        }

        if theme == .hidden {
            Image("hidden")
        }
    }
}

struct AppModeToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        AppModeToggleGroup(theme: .menubar)
            .frame(width: 200, height: 18)
    }
}
