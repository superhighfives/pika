import SwiftUI

private struct ShortcutEntry {
    let title: String
    let notificationName: Notification.Name
    let keys: [String]
}

private let row1: [ShortcutEntry] = [
    ShortcutEntry(title: PikaText.textPickForeground, notificationName: .triggerPickForeground, keys: ["⌘", "D"]),
    ShortcutEntry(title: PikaText.textPickBackground, notificationName: .triggerPickBackground, keys: ["⇧", "⌘", "D"]),
    ShortcutEntry(title: PikaText.textCopyForeground, notificationName: .triggerCopyForeground, keys: ["⌘", "C"]),
    ShortcutEntry(title: PikaText.textCopyBackground, notificationName: .triggerCopyBackground, keys: ["⇧", "⌘", "C"]),
    ShortcutEntry(title: PikaText.textColorSystemPickerForegroundSimple, notificationName: .triggerSystemPickerForeground, keys: ["⌘", "S"]),
]

private let row2: [ShortcutEntry] = [
    ShortcutEntry(title: PikaText.textColorSystemPickerBackgroundSimple, notificationName: .triggerSystemPickerBackground, keys: ["⇧", "⌘", "S"]),
    ShortcutEntry(title: PikaText.textColorUndo, notificationName: .triggerUndo, keys: ["⌘", "z"]),
    ShortcutEntry(title: PikaText.textColorRedo, notificationName: .triggerRedo, keys: ["⇧", "⌘", "Z"]),
    ShortcutEntry(title: PikaText.textColorSwapDetail, notificationName: .triggerSwap, keys: ["X"]),
    ShortcutEntry(title: PikaText.textHistoryToggle, notificationName: .toggleHistory, keys: ["H"]),
]

private let row3: [ShortcutEntry] = [
    ShortcutEntry(title: "\(PikaText.textMenuPreferences)...", notificationName: .triggerPreferences, keys: ["⌘", ","]),
    ShortcutEntry(title: PikaText.textMenuQuit, notificationName: .triggerQuit, keys: ["⌘", "Q"]),
    ShortcutEntry(title: PikaText.textFormatHex, notificationName: .triggerFormatHex, keys: ["⌘", "1"]),
    ShortcutEntry(title: PikaText.textFormatRGB, notificationName: .triggerFormatRGB, keys: ["⌘", "2"]),
    ShortcutEntry(title: PikaText.textFormatHSB, notificationName: .triggerFormatHSB, keys: ["⌘", "3"]),
]

private let row4: [ShortcutEntry] = [
    ShortcutEntry(title: PikaText.textFormatHSL, notificationName: .triggerFormatHSL, keys: ["⌘", "4"]),
    ShortcutEntry(title: PikaText.textFormatLAB, notificationName: .triggerFormatLAB, keys: ["⌘", "5"]),
    ShortcutEntry(title: PikaText.textFormatOpenGL, notificationName: .triggerFormatOpenGL, keys: ["⌘", "6"]),
    ShortcutEntry(title: PikaText.textFormatOKLCH, notificationName: .triggerFormatOKLCH, keys: ["⌘", "7"]),
]

private struct ShortcutRow: View {
    let entries: [ShortcutEntry]
    let unitWidth: CGFloat
    let unitHeight: CGFloat
    var padWithSpacer = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(entries.indices, id: \.self) { index in
                if index > 0 {
                    Divider().frame(height: unitHeight)
                }
                KeyboardShortcutItem(
                    title: entries[index].title,
                    notificationName: entries[index].notificationName,
                    keys: entries[index].keys
                )
                .frame(width: unitWidth, height: unitHeight)
            }
            if padWithSpacer {
                Divider().frame(height: unitHeight)
                Spacer()
            }
        }
    }
}

struct KeyboardShortcutGrid: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let unitWidth = width / 5
                let unitHeight = floor(height / 4)

                VStack(spacing: 0.0) {
                    ShortcutRow(entries: row1, unitWidth: unitWidth, unitHeight: unitHeight)

                    Divider().frame(maxWidth: .infinity)

                    ShortcutRow(entries: row2, unitWidth: unitWidth, unitHeight: unitHeight)

                    Divider().frame(maxWidth: .infinity)

                    ShortcutRow(entries: row3, unitWidth: unitWidth, unitHeight: unitHeight)

                    Divider().frame(maxWidth: .infinity)

                    ShortcutRow(entries: row4, unitWidth: unitWidth, unitHeight: unitHeight, padWithSpacer: true)
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
