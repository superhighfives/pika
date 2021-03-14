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
                            title: NSLocalizedString("color.pick.foreground", comment: "Pick foreground"),
                            event: PikaConstants.ncTriggerPickForeground,
                            keys: ["⌘", "D"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.pick.background", comment: "Pick background"),
                            event: PikaConstants.ncTriggerPickBackground,
                            keys: ["⇧", "⌘", "D"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.copy.foreground", comment: "Copy foreground"),
                            event: PikaConstants.ncTriggerCopyForeground,
                            keys: ["⌘", "C"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.copy.background", comment: "Copy background"),
                            event: PikaConstants.ncTriggerCopyBackground,
                            keys: ["⇧", "⌘", "C"]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: NSLocalizedString("menu.preferences", comment: "Preferences"),
                            event: PikaConstants.ncTriggerPreferences,
                            keys: ["⌘", ","]
                        )
                        .frame(width: horizontalUnit, height: verticalUnit)

                        Divider()
                            .frame(height: verticalUnit)

                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.swap.detail", comment: "Swap colors"),
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
