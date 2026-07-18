import Defaults
import SwiftUI

enum VerticalDirection {
    case up, down
}

struct ColorHistoryDrawer: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Environment(\.colorScheme) private var colorScheme

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
        AdaptiveDivider()
        VStack(spacing: 0) {
            PaletteTabBar(slideDirection: $slideDirection)
            AdaptiveDivider()
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
                    .translateVerticalScrollToHorizontal()
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
                    AdaptiveDivider(axis: .vertical)

                    if isAutoHistory {
                        Button(action: { isShowingClearConfirm = true }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
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
                AdaptivePanelBackground()
                // Barely-there tint so the drawer reads as almost the same surface as the
                // contrast footer — just a whisper of separation.
                Color.black.opacity(colorScheme == .dark ? 0.06 : 0.02)
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
