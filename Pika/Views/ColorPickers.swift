import SwiftUI

struct ColorPickers: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    /// Shared across both swatches rather than owned per-swatch: a click landing on either
    /// swatch's pick target while a colour field is focused needs to dismiss whichever swatch
    /// actually owns that field, not necessarily the one that was clicked (the window-wide
    /// first-responder check in `EyedropperButton.PickTarget` can't tell them apart on its own).
    /// Broadcasting the bump to both is harmless — only the swatch with an active session reacts.
    @State private var dismissEditingTrigger: Int = 0

    var body: some View {
        let eyedropperArray: [Eyedropper] = [eyedroppers.foreground, eyedroppers.background]

        HStack(spacing: 0.0) {
            ForEach(Array(eyedropperArray.enumerated()), id: \.element.type) { _, eyedropper in
                // No divider between the two swatches — the colours meet directly, and the
                // horizontal section dividers do the framing.
                EyedropperItem(eyedropper: eyedropper, dismissEditingTrigger: $dismissEditingTrigger)
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
