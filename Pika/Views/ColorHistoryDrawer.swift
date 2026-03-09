import Defaults
import SwiftUI

struct ColorHistoryChip: View {
    let pair: ColorPair
    let isActive: Bool
    let onApplyBoth: () -> Void
    let onApplyForeground: () -> Void
    let onApplyBackground: () -> Void
    let onApplySwapped: () -> Void
    let onRemove: () -> Void
    let onClearAll: () -> Void

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.clear)
            .frame(width: 44, height: 44)
            .overlay(
                VStack(spacing: 0) {
                    Color(pair.foregroundColor)
                    Color(pair.backgroundColor)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .opacity(isActive ? 1 : 0)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(radius: isHovered ? 3 : 0)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .onHover { hovering in isHovered = hovering }
            .onTapGesture { onApplyBoth() }
            .contextMenu {
                Button(PikaText.textHistoryApplyForeground, action: onApplyForeground)
                Button(PikaText.textHistoryApplyBackground, action: onApplyBackground)
                Button(PikaText.textHistoryApplySwapped, action: onApplySwapped)
                Divider()
                Button(PikaText.textHistoryRemove, action: onRemove)
                Button(PikaText.textHistoryClear, action: onClearAll)
            }
            .help("\(pair.foregroundHex) / \(pair.backgroundHex)")
    }
}

struct ColorHistoryDrawer: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Default(.colorHistory) var colorHistory

    var body: some View {
        Divider()
        VStack(alignment: .leading, spacing: 0) {
            Text(PikaText.textHistoryTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(colorHistory) { pair in
                        ColorHistoryChip(
                            pair: pair,
                            isActive: isActivePair(pair),
                            onApplyBoth: { applyBoth(pair) },
                            onApplyForeground: { applyForeground(pair) },
                            onApplyBackground: { applyBackground(pair) },
                            onApplySwapped: { applySwapped(pair) },
                            onRemove: { removePair(pair) },
                            onClearAll: { Defaults[.colorHistory] = [] }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 76, alignment: .leading)
        .background(
            ZStack {
                VisualEffect(
                    material: NSVisualEffectView.Material.underWindowBackground,
                    blendingMode: NSVisualEffectView.BlendingMode.behindWindow
                )
                Color.black.opacity(0.2)
            }
        )
    }

    private func isActivePair(_ pair: ColorPair) -> Bool {
        pair.foregroundHex == foreground.color.toHexString() &&
            pair.backgroundHex == background.color.toHexString()
    }

    private func applyBoth(_ pair: ColorPair) {
        eyedroppers.foreground.set(pair.foregroundColor)
        eyedroppers.background.set(pair.backgroundColor)
    }

    private func applyForeground(_ pair: ColorPair) {
        eyedroppers.foreground.set(pair.foregroundColor)
    }

    private func applyBackground(_ pair: ColorPair) {
        eyedroppers.background.set(pair.backgroundColor)
    }

    private func applySwapped(_ pair: ColorPair) {
        eyedroppers.foreground.set(pair.backgroundColor)
        eyedroppers.background.set(pair.foregroundColor)
    }

    private func removePair(_ pair: ColorPair) {
        Defaults[.colorHistory] = colorHistory.filter { $0.id != pair.id }
    }
}
