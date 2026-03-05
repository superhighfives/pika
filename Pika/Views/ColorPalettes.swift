import SwiftUI

struct ColorPalettes: View {
    let palettes: [ColorPalette]
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        ForEach(palettes) { palette in
            Divider()
            ColorPaletteBar(palette: palette)
                .environmentObject(eyedroppers)
                .swatchSectionStyle()
        }
    }
}
