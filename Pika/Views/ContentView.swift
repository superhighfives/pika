import Defaults
import SwiftUI

struct ContentView: View {
    @ObservedObject var eyedropperForeground = Eyedropper(
        title: "Foreground", color: PikaConstants.initialColors.randomElement()!
    )
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: NSColor.black)

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        let eyedroppers: [Eyedropper] = [eyedropperForeground, eyedropperBackground]

        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            HStack(spacing: 0.0) {
                ForEach(eyedroppers, id: \.title) { eyedropper in
                    let uiColor: Color = eyedropper.color.luminance < 0.333 ? Color.white : Color.black

                    ZStack {
                        EyedropperButton(eyedropper: eyedropper, uiColor: uiColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ColorMenu(eyedropper: eyedropper)
                            .shadow(radius: 0, x: 0, y: 1)
                            .opacity(0.8)
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(8.0)
                    }

                    Divider()
                }
            }
            .clipped()

            Divider()

            Footer(
                foreground: self.$eyedropperForeground.color,
                background: self.$eyedropperBackground.color
            )
        }
        .onAppear {
            eyedropperBackground.set(color: colorScheme == .light
                ? NSColor(r: 255.0, g: 255.0, b: 255.0)
                : NSColor(r: 0.0, g: 0.0, b: 0.0)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
