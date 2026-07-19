import SwiftUI

struct ColorPickers: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        let eyedropperArray: [Eyedropper] = [eyedroppers.foreground, eyedroppers.background]

        HStack(spacing: 0.0) {
            ForEach(Array(eyedropperArray.enumerated()), id: \.element.type) { _, eyedropper in
                // No divider between the two swatches — the colours meet directly, and the
                // horizontal section dividers do the framing.
                EyedropperItem(eyedropper: eyedropper)
            }
        }
    }
}

struct ColorPickers_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickers()
            .environmentObject(Eyedroppers())
    }
}
