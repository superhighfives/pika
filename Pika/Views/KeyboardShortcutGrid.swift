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
                let entries = PikaShortcuts.all
                let rowCount = (entries.count + Self.columnsPerRow - 1) / Self.columnsPerRow
                let unitHeight = floor(height / CGFloat(rowCount))

                let rows = stride(from: entries.startIndex, to: entries.endIndex, by: Self.columnsPerRow)
                    .map { start in entries[start ..< min(start + Self.columnsPerRow, entries.endIndex)] }

                VStack(spacing: 0.0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 {
                            Divider().frame(maxWidth: .infinity)
                        }
                        ShortcutRow(
                            entries: row,
                            unitWidth: unitWidth,
                            unitHeight: unitHeight,
                            padWithSpacer: row.count < Self.columnsPerRow
                        )
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
