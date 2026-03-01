import Defaults
import SwiftUI

struct ColorHistory: View {
    @Default(.colorHistory) var colorHistory
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        let colors = Array(colorHistory.prefix(ColorHistoryManager.maxEntries))
        if !colors.isEmpty {
            Divider()
            SwatchBar(
                title: PikaText.textColorHistory,
                swatches: colors.map { Swatch(id: $0, color: NSColor(hex: $0), hex: $0, name: nil) },
                onTap: { swatch in
                    eyedroppers.foreground.applyFromSwatch(swatch.color)
                    eyedroppers.foreground.promoteInHistory(hex: swatch.hex)
                }
            )
            .swatchSectionStyle()
        }
    }
}
