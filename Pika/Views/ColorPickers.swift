import SwiftUI

struct ColorPickers: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        let eyedropperArray: [Eyedropper] = [eyedroppers.foreground, eyedroppers.background]

        HStack(spacing: 0.0) {
            ForEach(Array(eyedropperArray.enumerated()), id: \.element.type) { index, eyedropper in
                if index > 0 {
                    Divider()
                }
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
