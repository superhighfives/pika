import Defaults
import SwiftUI

struct AppModeToggleGroup: View {
    var theme: Themes

    enum Themes: String, Codable, CaseIterable {
        case menubar
        case regular
        case menubarPopover
//        case hidden
    }

    var body: some View {
        if theme == .menubar {
            Image("menubar-wide")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }

        if theme == .regular {
            Image("dock-wide")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }

        if theme == .menubarPopover {
            Image("menubar-popover-wide")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }

//        if theme == .hidden {
//            Image("hidden")
//        }
    }
}

struct AppModeToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        AppModeToggleGroup(theme: .menubar)
            .frame(width: 200, height: 18)
    }
}
