import Defaults
import SwiftUI

struct ColorHistoryChip: View {
    let pair: ColorPair
    let isActive: Bool
    let onApplyBoth: () -> Void
    let onApplyForeground: () -> Void
    let onApplyBackground: () -> Void
    let onRemove: () -> Void
    let onClearAll: (() -> Void)?
    var isAutoHistory: Bool = true

    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat

    @State private var isHovered = false
    @State private var colorSpace = Defaults[.colorSpace]

    private func formatted(_ color: NSColor) -> String {
        (color.usingColorSpace(colorSpace) ?? color).toFormat(format: colorFormat, style: copyFormat)
    }

    /// The palettes sidebar's tile (`SidebarSwatch`), sized for the drawer's row: "Aa" in the
    /// pair's own colours, with its contrast ratio under it.
    @Default(.paletteSwatchStyle) private var swatchStyle

    /// The palettes sidebar's tile (`SidebarSwatch`), sized for the drawer's row, with the pair's
    /// contrast under it.
    var body: some View {
        VStack(spacing: 2) {
            PairTile(pair: pair, fontSize: 12)
                // The stacked style keeps its original square.
                .frame(width: swatchStyle == .stacked ? 24 : 34, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .opacity(isActive ? 1 : 0)
                )
                .shadow(color: .black.opacity(isHovered ? 0.25 : 0), radius: 3, y: 1)
            SwatchContrastLabel(pair: pair, fontSize: 9)
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture { onApplyBoth() }
        .contextMenu {
            Button(PikaText.textHistoryApplyForeground, action: onApplyForeground)
            Button(PikaText.textHistoryApplyBackground, action: onApplyBackground)
            Divider()
            Button(isAutoHistory ? PikaText.textHistoryRemove : PikaText.textPaletteRemoveChip, action: onRemove)
            if let onClearAll = onClearAll {
                Button(PikaText.textHistoryClear, action: onClearAll)
            }
        }
        .help("\(formatted(pair.foregroundColor)) / \(formatted(pair.backgroundColor))")
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            colorSpace = Defaults[.colorSpace]
        }
    }
}

struct PaletteNameField: View {
    let placeholder: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .focused($isFocused)
                .onSubmit { submit() }
                .onExitCommand { onCancel() }
                .frame(width: 120)

            Button(action: { submit() }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)

            Button(action: { onCancel() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        )
        .onAppear { isFocused = true }
    }

    private func submit() {
        let name = text.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onSubmit(name)
    }
}

struct PaletteTabBar: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Binding var slideDirection: VerticalDirection

    @State private var isShowingNewField = false
    @State private var renamingIndex: Int?

    private func scrollToEnd(proxy: ScrollViewProxy) {
        let target = isShowingNewField ? "newPaletteField" : "addButton"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                proxy.scrollTo(target, anchor: .trailing)
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(palettes.enumerated()), id: \.element.id) { index, palette in
                        if renamingIndex == index {
                            PaletteNameField(
                                placeholder: palette.name ?? PikaText.textPaletteNamePlaceholder,
                                onSubmit: { name in
                                    eyedroppers.renamePalette(at: index, to: name)
                                    renamingIndex = nil
                                },
                                onCancel: { renamingIndex = nil }
                            )
                        } else {
                            paletteTab(palette: palette, index: index)
                        }
                    }

                    if isShowingNewField {
                        PaletteNameField(
                            placeholder: PikaText.textPaletteNamePlaceholder,
                            onSubmit: { name in
                                slideDirection = .down
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    eyedroppers.savePalette(name: name)
                                }
                                isShowingNewField = false
                            },
                            onCancel: { isShowingNewField = false }
                        )
                        .id("newPaletteField")
                    } else {
                        Button(action: { isShowingNewField = true }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 22)
                        }
                        .buttonStyle(.plain)
                        .help(PikaText.textPaletteNew)
                        .id("addButton")
                    }
                }
                .padding(.horizontal, 8)
            }
            .translateVerticalScrollToHorizontal()
            .onChange(of: isShowingNewField) { _, _ in
                scrollToEnd(proxy: proxy)
            }
            .onChange(of: palettes.count) { _, _ in
                scrollToEnd(proxy: proxy)
            }
        }
        .frame(height: ColorHistoryDrawer.tabBarHeight)
        .background(Color.black.opacity(0.05))
        .onReceive(NotificationCenter.default.publisher(for: .savePalette)) { _ in
            if !historyDrawerVisible {
                withAnimation(.easeInOut(duration: 0.25)) {
                    historyDrawerVisible = true
                }
            }
            isShowingNewField = true
        }
    }

    @ViewBuilder
    private func paletteTab(palette: Palette, index: Int) -> some View {
        let isSelected = index == activePaletteIndex

        Button(action: {
            slideDirection = index > activePaletteIndex ? .down : .up
            withAnimation(.easeInOut(duration: 0.2)) {
                activePaletteIndex = index
            }
            if index == 0 { eyedroppers.restoreAutoHistorySelection() }
        }) {
            if palette.isAutoHistory {
                Image(systemName: "clock")
                    .font(.system(size: 10))
            } else {
                Text(palette.name ?? "")
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contextMenu {
            if palette.isAutoHistory {
                Button(PikaText.textHistoryExport) {
                    NotificationCenter.default.post(name: .exportPalette, object: index)
                }
            } else {
                Button(PikaText.textPaletteRename) {
                    renamingIndex = index
                }
                Button(PikaText.textPaletteExport) {
                    NotificationCenter.default.post(name: .exportPalette, object: index)
                }
                Divider()
                Button(PikaText.textPaletteDelete) {
                    eyedroppers.deletePalette(at: index)
                }
            }
        }
    }
}

/// A pair's tile: "Aa" in the foreground colour on the background, or the two colours stacked,
/// as Settings → Palette Swatches chooses. Sized and shaped by the caller.
struct PairTile: View {
    let pair: ColorPair
    let fontSize: CGFloat

    @Default(.paletteSwatchStyle) private var style

    var body: some View {
        switch style {
        case .text:
            Text("Aa")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(Color(pair.foregroundColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(pair.backgroundColor))
        case .stacked:
            VStack(spacing: 0) {
                Color(pair.foregroundColor)
                Color(pair.backgroundColor)
            }
        }
    }
}

/// The contrast under a palette swatch, in the standard the contrast bar uses: the WCAG ratio, or
/// APCA's Lc. Nothing with both, which wouldn't fit. Bold when it passes for body text (WCAG
/// 4.5:1, APCA Lc 75).
struct SwatchContrastLabel: View {
    let pair: ColorPair
    let fontSize: CGFloat

    @Default(.contrastStandard) private var standard

    var body: some View {
        if let (text, passes) = value {
            Text(text)
                .font(.system(size: fontSize, weight: passes ? .semibold : .regular))
                .foregroundStyle(passes ? Color.primary.opacity(0.85) : Color.secondary)
                .monospacedDigit()
        }
    }

    private var value: (String, Bool)? {
        switch standard {
        case .wcag:
            let ratio = pair.foregroundColor.contrastRatio(with: pair.backgroundColor)
            return (String(format: "%.1f", ratio), ratio >= 4.5)
        case .apca:
            let contrast = abs(pair.foregroundColor.toAPCACompliance(with: pair.backgroundColor).value)
            return (String(format: "%.0f", contrast), contrast >= 75)
        case .both:
            return nil
        }
    }
}
