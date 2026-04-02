import SwiftUI

struct SwapPreviewButton: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    let showPreview: Bool
    let isVisible: Bool
    let onSwap: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered: Bool = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var angle: Double = 0

    private var bgColor: Color {
        showPreview
            ? Color(background.color)
            : Color.pikaControlBackground(for: colorScheme)
    }

    private var fgColor: Color {
        showPreview
            ? Color(foreground.color)
            : (colorScheme == .dark ? Color.white : Color.black)
    }

    var body: some View {
        Button(action: { onSwap(); angle -= 180 }) {
            HStack(spacing: 6.0) {
                IconImage(name: "arrow.triangle.swap")
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut, value: angle)

                if showPreview {
                    Text(PikaText.textColorSwap)
                        .font(.system(size: 12.0))
                    Rectangle()
                        .fill(fgColor.opacity(0.25))
                        .frame(width: 1, height: 14)
                        .padding(.horizontal, 2.0)
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold))
                    Text(NSLocalizedString("color.preview.sample", comment: "Sample preview text"))
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if isHovered {
                    Text(PikaText.textColorSwap)
                        .font(.system(size: 12.0))
                        .padding(.trailing, 2.0)
                }
            }
            .foregroundColor(fgColor.opacity(0.8))
            .padding(.horizontal, 8.0)
            .padding(.vertical, 8.0)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(bgColor)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                        .stroke(
                            showPreview
                                ? (colorScheme == .dark
                                    ? Color.black.opacity(0.2)
                                    : Color.white.opacity(0.3))
                                : fgColor.opacity(0.1)
                        )
                )
        )
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut, value: isVisible)
        .onHover { hover in
            if hover {
                guard hoverTask == nil else { return }
                hoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    isHovered = true
                    hoverTask = nil
                }
            } else {
                hoverTask?.cancel()
                hoverTask = nil
                isHovered = false
            }
        }
    }
}
