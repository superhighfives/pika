import SwiftUI

/// Natural height of a swatch's readout block, reduced across both swatches with `max`.
/// The taller of the two wins so the boundary hairline sits at one height across the pair
/// rather than stepping where a value happens to wrap onto a second line.
struct ReadoutHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = Swift.max(value, nextValue())
    }
}

struct ColorPickers: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    /// Shared across both swatches rather than owned per-swatch: a click landing on either
    /// swatch's pick target while a colour field is focused needs to dismiss whichever swatch
    /// actually owns that field, not necessarily the one that was clicked (the window-wide
    /// first-responder check in `EyedropperButton.PickTarget` can't tell them apart on its own).
    /// Broadcasting the bump to both is harmless — only the swatch with an active session reacts.
    @State private var dismissEditingTrigger: Int = 0
    /// Tallest readout block of the two, applied to both — see `ReadoutHeightKey`.
    @State private var readoutHeight: CGFloat = 0
    /// Hovering either swatch shows the boundary on both: it marks where the pair stops being
    /// a pick target, which is one fact about the whole row, not a per-swatch one.
    @State private var pickersHovered = false

    var body: some View {
        let eyedropperArray: [Eyedropper] = [eyedroppers.foreground, eyedroppers.background]

        HStack(spacing: 0.0) {
            ForEach(Array(eyedropperArray.enumerated()), id: \.element.type) { _, eyedropper in
                // No divider between the two swatches — the colours meet directly, and the
                // horizontal section dividers do the framing.
                EyedropperItem(
                    eyedropper: eyedropper,
                    dismissEditingTrigger: $dismissEditingTrigger,
                    readoutHeight: readoutHeight,
                    showsReadoutBoundary: pickersHovered
                )
            }
        }
        .onPreferenceChange(ReadoutHeightKey.self) { height in
            // Deferred: this fires from within the layout pass that measured it, and writing
            // state straight back re-enters that pass (the same reentrancy that silently dropped
            // the swatch-width measurement in `EditableColorValue`).
            DispatchQueue.main.async { readoutHeight = height }
        }
        .onHover { pickersHovered = $0 }
    }
}

struct ColorPickers_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickers()
            .environmentObject(Eyedroppers())
    }
}
