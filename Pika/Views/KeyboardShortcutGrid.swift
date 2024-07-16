import SwiftUI

struct KeyboardShortcutGrid: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

                let quarterHorizontalUnit = width / 4
                let verticalUnit = floor(height / 3)

                VStack(spacing: 0.0) {
                    // Pick
                    HStack(spacing: 0.0) {
                        KeyboardShortcutItem(
                            title: PikaText.textPickForeground,
                            event: PikaConstants.ncTriggerPickForeground,
                            keys: ["⌘", "D"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textPickBackground,
                            event: PikaConstants.ncTriggerPickBackground,
                            keys: ["⇧", "⌘", "D"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textCopyForeground,
                            event: PikaConstants.ncTriggerCopyForeground,
                            keys: ["⌘", "C"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textCopyBackground,
                            event: PikaConstants.ncTriggerCopyBackground,
                            keys: ["⇧", "⌘", "C"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    // Copy
                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: PikaText.textColorUndo,
                            event: PikaConstants.ncTriggerUndo,
                            keys: ["⌘", "z"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textColorRedo,
                            event: PikaConstants.ncTriggerRedo,
                            keys: ["⌘", "Z"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textColorSwapDetail,
                            event: PikaConstants.ncTriggerSwap,
                            keys: ["⇧", "⌘", "X"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: "\(PikaText.textMenuPreferences)...",
                            event: PikaConstants.ncTriggerPreferences,
                            keys: ["⌘", ","]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: PikaText.textFormatHex,
                            event: PikaConstants.ncTriggerFormatHex,
                            keys: ["⌘", "1"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textFormatRGB,
                            event: PikaConstants.ncTriggerFormatRGB,
                            keys: ["⌘", "2"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textFormatHSB,
                            event: PikaConstants.ncTriggerFormatHSB,
                            keys: ["⌘", "3"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textFormatHSL,
                            event: PikaConstants.ncTriggerFormatHSL,
                            keys: ["⌘", "4"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textFormatOpenGL,
                            event: PikaConstants.ncTriggerFormatOpenGL,
                            keys: ["⌘", "5"]
                        )
                        .frame(width: quarterHorizontalUnit, height: verticalUnit)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
                .offset(y: 1)
        }
    }
}

struct KeyboardShortcutGrid_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutGrid()
    }
}
