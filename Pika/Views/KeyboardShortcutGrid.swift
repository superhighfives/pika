import SwiftUI

struct KeyboardShortcutGrid: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

                let horizontalUnit = width / 2
                let verticalUnit = floor(height / 3)

                VStack(spacing: 0.0) {
                    HStack(spacing: 0.0) {
                        KeyboardShortcutItem(
                            title: PikaText.textPickForeground,
                            event: PikaConstants.ncTriggerPickForeground,
                            keys: ["⌘", "D"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textPickBackground,
                            event: PikaConstants.ncTriggerPickBackground,
                            keys: ["⇧", "⌘", "D"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: PikaText.textCopyForeground,
                            event: PikaConstants.ncTriggerCopyForeground,
                            keys: ["⌘", "C"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textCopyBackground,
                            event: PikaConstants.ncTriggerCopyBackground,
                            keys: ["⇧", "⌘", "C"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: "\(PikaText.textMenuPreferences)...",
                            event: PikaConstants.ncTriggerPreferences,
                            keys: ["⌘", ","]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: PikaText.textColorSwapDetail,
                            event: PikaConstants.ncTriggerSwap,
                            keys: ["⇧", "⌘", "X"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)
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
