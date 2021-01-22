import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
        .onAppear {
            eyedroppers.background.color = colorScheme == .light
                ? NSColor.white
                : NSColor.black
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
