import SwiftUI

struct KeyboardShortcutGrid: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                VStack(spacing: 0.0) {
                    HStack(spacing: 0.0) {
                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.pick.foreground", comment: "Pick foreground"),
                            event: PikaConstants.ncTriggerPickForeground,
                            keys: ["⌘", "D"]
                        )
                        .frame(width: width / 2, height: height / 2)

                        Divider()
                            .frame(height: height / 2)

                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.pick.background", comment: "Pick background"),
                            event: PikaConstants.ncTriggerPickBackground,
                            keys: ["⇧", "⌘", "D"]
                        )
                        .frame(width: width / 2, height: height / 2)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.copy.foreground", comment: "Copy foreground"),
                            event: PikaConstants.ncTriggerCopyForeground,
                            keys: ["⌘", "C"]
                        )
                        .frame(width: width / 2, height: height / 2)

                        Divider()
                            .frame(height: height / 2)

                        KeyboardShortcutItem(
                            title: NSLocalizedString("color.copy.background", comment: "Copy background"),
                            event: PikaConstants.ncTriggerCopyBackground,
                            keys: ["⇧", "⌘", "C"]
                        )
                        .frame(width: width / 2, height: height / 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
        }
    }
}

struct KeyboardShortcutGrid_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutGrid()
    }
}
