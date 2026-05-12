import Defaults
import SwiftUI

enum VerticalDirection {
    case up, down
}

struct ColorHistoryChip: View {
    let pair: ColorPair
    let isActive: Bool
    let onApplyBoth: () -> Void
    let onApplyForeground: () -> Void
    let onApplyBackground: () -> Void
    let onRemove: () -> Void
    let onClearAll: (() -> Void)?
    var isAutoHistory: Bool = true

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.clear)
            .frame(width: 24, height: 24)
            .overlay(
                VStack(spacing: 0) {
                    Color(pair.foregroundColor)
                    Color(pair.backgroundColor)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .opacity(isActive ? 1 : 0)
            )
            .shadow(radius: isHovered ? 3 : 0)
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
            .help("\(pair.foregroundHex) / \(pair.backgroundHex)")
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
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)

            Button(action: { onCancel() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 22)
                        }
                        .buttonStyle(.plain)
                        .help(PikaText.textPaletteNew)
                        .id("addButton")
                    }
                }
                .padding(.horizontal, 8)
            }
            .onChange(of: isShowingNewField) { _, _ in
                scrollToEnd(proxy: proxy)
            }
            .onChange(of: palettes.count) { _, _ in
                scrollToEnd(proxy: proxy)
            }
        }
        .frame(height: 28)
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
        .foregroundColor(isSelected ? .accentColor : .secondary)
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

struct ColorHistoryDrawer: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex

    @State private var isShowingClearConfirm = false
    @State private var slideDirection: VerticalDirection = .down

    private var activePalette: Palette? {
        let idx = activePaletteIndex
        guard idx >= 0, idx < palettes.count else {
            DispatchQueue.main.async { activePaletteIndex = 0 }
            return palettes.first
        }
        return palettes[idx]
    }

    private var isAutoHistory: Bool {
        activePalette?.isAutoHistory ?? false
    }

    var body: some View {
        Divider()
        VStack(spacing: 0) {
            PaletteTabBar(slideDirection: $slideDirection)
            Divider()
            HStack(spacing: 0) {
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array((activePalette?.pairs ?? []).enumerated()), id: \.element.id) { _, pair in
                                ColorHistoryChip(
                                    pair: pair,
                                    isActive: isActivePair(pair),
                                    onApplyBoth: { applyBoth(pair) },
                                    onApplyForeground: { applyForeground(pair) },
                                    onApplyBackground: { applyBackground(pair) },
                                    onRemove: { removePair(pair) },
                                    onClearAll: isAutoHistory ? { isShowingClearConfirm = true } : nil,
                                    isAutoHistory: isAutoHistory
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .animation(.easeInOut(duration: 0.2), value: activePalette?.pairs)
                    }
                    .id(activePalette?.id)
                    .transition(slideTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: 44)
                .clipped()
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 6)
                }

                HStack(spacing: 0) {
                    Divider()

                    if isAutoHistory {
                        Button(action: { isShowingClearConfirm = true }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(x: -2, y: -2)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(PikaText.textHistoryClear)
                    } else {
                        Button(action: {
                            eyedroppers.addCurrentToPalette(at: activePaletteIndex)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(x: -2, y: -2)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(PikaText.textPaletteAddColor)
                    }
                }
                .frame(width: 50)
            }
            .frame(maxWidth: .infinity, maxHeight: 44, alignment: .leading)
        }
        .background(
            ZStack {
                VisualEffect(
                    material: NSVisualEffectView.Material.underWindowBackground,
                    blendingMode: NSVisualEffectView.BlendingMode.behindWindow
                )
                Color.black.opacity(0.2)
            }
        )
        .alert(PikaText.textHistoryClear, isPresented: $isShowingClearConfirm) {
            Button(PikaText.textClear, role: .destructive) {
                eyedroppers.clearHistory()
            }
            Button(PikaText.textCancel, role: .cancel) {}
        } message: {
            Text(PikaText.textHistoryClearConfirm)
        }
    }

    private var slideTransition: AnyTransition {
        let direction: CGFloat = slideDirection == .down ? 1 : -1
        return .asymmetric(
            insertion: .offset(y: 44 * direction),
            removal: .offset(y: -44 * direction)
        )
    }

    private func isActivePair(_ pair: ColorPair) -> Bool {
        pair.id == eyedroppers.activeHistoryID
    }

    private func applyBoth(_ pair: ColorPair) {
        eyedroppers.applyHistoryEntry(pair)
    }

    private func applyForeground(_ pair: ColorPair) {
        eyedroppers.foreground.set(pair.foregroundColor)
        eyedroppers.recordHistory()
    }

    private func applyBackground(_ pair: ColorPair) {
        eyedroppers.background.set(pair.backgroundColor)
        eyedroppers.recordHistory()
    }

    private func removePair(_ pair: ColorPair) {
        if isAutoHistory {
            eyedroppers.deleteHistoryEntry(id: pair.id)
        } else {
            eyedroppers.deleteChipFromPalette(paletteIndex: activePaletteIndex, pairID: pair.id)
        }
    }
}
