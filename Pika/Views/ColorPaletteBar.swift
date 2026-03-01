import SwiftUI

struct ColorPaletteBar: View {
    let palette: ColorPalette
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        SwatchBar(
            title: palette.name,
            // Index-based IDs because a palette can contain duplicate colors.
            swatches: palette.colors.enumerated().map { index, color in
                Swatch(
                    id: "\(palette.id):\(index)",
                    color: color.color,
                    hex: color.hex,
                    name: color.name
                )
            },
            onTap: { swatch in
                eyedroppers.foreground.applyFromSwatch(swatch.color)
            }
        )
    }
}
