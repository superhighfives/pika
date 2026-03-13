import Defaults
import SwiftUI

struct ColorHistoryChip: View {
    let pair: ColorPair
    let isActive: Bool
    let onApplyBoth: () -> Void
    let onApplyForeground: () -> Void
    let onApplyBackground: () -> Void
    let onRemove: () -> Void
    let onClearAll: () -> Void

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
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(colorHistory) { pair in
                        ColorHistoryChip(
                            pair: pair,
                            isActive: isActivePair(pair),
                            onApplyBoth: { applyBoth(pair) },
                            onApplyForeground: { applyForeground(pair) },
                            onApplyBackground: { applyBackground(pair) },
                            onRemove: { removePair(pair) },
                            onClearAll: { eyedroppers.clearHistory() }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: colorHistory)
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

                    Button(action: { eyedroppers.clearHistory() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                    .help(PikaText.textHistoryClear)
                    .frame(width: 38)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
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
        eyedroppers.deleteHistoryEntry(id: pair.id)
    }
}
