import SwiftUI

struct ColorPickers: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        let eyedropperArray: [Eyedropper] = [eyedroppers.foreground, eyedroppers.background]

        HStack(spacing: 0.0) {
            ForEach(eyedropperArray, id: \.title) { eyedropper in
                EyedropperItem(eyedropper: eyedropper)

                Divider()
            }
        }
        .clipped()
    }
}

struct ColorPickers_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickers()
            .environmentObject(Eyedroppers())
    }
}
