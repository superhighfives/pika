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

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.clear)
            .frame(width: 30, height: 30)
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
                Button(PikaText.textHistoryRemove, action: onRemove)
                if let onClearAll = onClearAll {
                    Button(PikaText.textHistoryClear, action: onClearAll)
                }
            }
            .help("\(pair.foregroundHex) / \(pair.backgroundHex)")
    }
}

struct PaletteTabBar: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex

    @State private var isShowingSaveAlert = false
    @State private var newPaletteName = ""
    @State private var renamingIndex: Int?
    @State private var renameText = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(palettes.enumerated()), id: \.element.id) { index, palette in
                    paletteTab(palette: palette, index: index)
                }

                Button(action: { promptSavePalette() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 22)
                }
                .buttonStyle(.plain)
                .help(PikaText.textPaletteNew)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 28)
        .background(Color.black.opacity(0.05))
        .alert(PikaText.textPaletteNamePrompt, isPresented: $isShowingSaveAlert) {
            TextField(PikaText.textPaletteNamePlaceholder, text: $newPaletteName)
            Button("Save") {
                let name = newPaletteName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    eyedroppers.savePalette(name: name)
                }
                newPaletteName = ""
            }
            Button("Cancel", role: .cancel) { newPaletteName = "" }
        }
        .alert(PikaText.textPaletteRename, isPresented: Binding(
            get: { renamingIndex != nil },
            set: { if !$0 { renamingIndex = nil } }
        )) {
            TextField(PikaText.textPaletteNamePlaceholder, text: $renameText)
            Button("Rename") {
                if let idx = renamingIndex {
                    let name = renameText.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        eyedroppers.renamePalette(at: idx, to: name)
                    }
                }
                renamingIndex = nil
                renameText = ""
            }
            Button("Cancel", role: .cancel) {
                renamingIndex = nil
                renameText = ""
            }
        }
    }

    @ViewBuilder
    private func paletteTab(palette: Palette, index: Int) -> some View {
        let isSelected = index == activePaletteIndex

        Button(action: { activePaletteIndex = index }) {
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
                    renameText = palette.name ?? ""
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

    private func promptSavePalette() {
        newPaletteName = ""
        isShowingSaveAlert = true
    }
}

struct ColorHistoryDrawer: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex

    @State private var isShowingClearConfirm = false

    private var activePalette: Palette? {
        let idx = activePaletteIndex
        guard idx >= 0, idx < palettes.count else { return palettes.first }
        return palettes[idx]
    }

    private var isAutoHistory: Bool {
        activePaletteIndex == 0
    }

    var body: some View {
        Divider()
        VStack(spacing: 0) {
            PaletteTabBar()
            Divider()
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(activePalette?.pairs ?? []) { pair in
                            ColorHistoryChip(
                                pair: pair,
                                isActive: isActivePair(pair),
                                onApplyBoth: { applyBoth(pair) },
                                onApplyForeground: { applyForeground(pair) },
                                onApplyBackground: { applyBackground(pair) },
                                onRemove: { removePair(pair) },
                                onClearAll: isAutoHistory ? { isShowingClearConfirm = true } : nil
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: activePalette?.pairs)
                    .padding(.horizontal, 12)
                }

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 6)
                        .offset(x: -6)

                    HStack(spacing: 0) {
                        Divider()

                        if isAutoHistory {
                            Button(action: { isShowingClearConfirm = true }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                            .help(PikaText.textHistoryClear)
                            .frame(width: 38)
                        } else {
                            Button(action: {
                                eyedroppers.addCurrentToPalette(at: activePaletteIndex)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                            .help(PikaText.textPaletteAddColor)
                            .frame(width: 38)
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
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
            Button("Clear", role: .destructive) {
                eyedroppers.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(PikaText.textHistoryClearConfirm)
        }
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
