import SwiftUI

private struct ShortcutRow: View {
    let entries: ArraySlice<PikaShortcut>
    let unitWidth: CGFloat
    let unitHeight: CGFloat
    var padWithSpacer = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(entries.indices, id: \.self) { index in
                if index > entries.startIndex {
                    Divider().frame(height: unitHeight)
                }
                KeyboardShortcutItem(
                    title: entries[index].title,
                    notificationName: entries[index].notificationName,
                    keys: entries[index].displayKeys
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
    private static let columnsPerRow = 5

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let unitWidth = width / CGFloat(Self.columnsPerRow)
                let unitHeight = floor(height / 4)
                let entries = PikaShortcuts.all

                VStack(spacing: 0.0) {
                    ShortcutRow(entries: entries[0 ..< 5], unitWidth: unitWidth, unitHeight: unitHeight)
                    Divider().frame(maxWidth: .infinity)
                    ShortcutRow(entries: entries[5 ..< 10], unitWidth: unitWidth, unitHeight: unitHeight)
                    Divider().frame(maxWidth: .infinity)
                    ShortcutRow(entries: entries[10 ..< 15], unitWidth: unitWidth, unitHeight: unitHeight)
                    Divider().frame(maxWidth: .infinity)
                    ShortcutRow(
                        entries: entries[15 ..< entries.count],
                        unitWidth: unitWidth,
                        unitHeight: unitHeight,
                        padWithSpacer: entries.count - 15 < Self.columnsPerRow
                    )
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
