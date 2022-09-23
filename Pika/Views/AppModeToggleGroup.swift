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
            HStack(spacing: 16.0) {}
        }

        if theme == .regular {
            HStack(spacing: 12.0) {}
        }

        if theme == .hidden {
            HStack(spacing: 12.0) {}
        }
    }
}

struct AppModeToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        AppModeToggleGroup(theme: .menubar)
            .frame(width: 200, height: 18)
    }
}
