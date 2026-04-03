import SwiftUI

struct PreviewPill: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Environment(\.colorScheme) var colorScheme

    private var bgColor: Color { Color(background.color) }
    private var fgColor: Color { Color(foreground.color) }

    var body: some View {
        HStack(spacing: 6.0) {
            Text("Aa")
                .font(.system(size: 15, weight: .bold))
            Text(NSLocalizedString("color.preview.sample", comment: "Sample preview text"))
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundColor(fgColor.opacity(0.8))
        .padding(.horizontal, 10.0)
        .padding(.vertical, 8.0)
        .background(
            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(bgColor)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                        .stroke(
                            colorScheme == .dark
                                ? Color.black.opacity(0.2)
                                : Color.white.opacity(0.3)
                        )
                )
        )
    }
}

struct SwapPreviewButton: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    let showPreview: Bool
    let isVisible: Bool
    let onSwap: () -> Void

    @State private var angle: Double = 0
    @State private var displayMode: DisplayMode = .standalone
    @State private var fadePhase: FadePhase = .visible
    @State private var swapHovered: Bool = false

    private enum DisplayMode {
        case preview, standalone
    }

    private enum FadePhase {
        case visible, fadingOut
    }

    private var swapButton: some View {
        Button(action: { onSwap(); angle -= 180 }) {
            IconImage(name: "arrow.triangle.swap")
                .rotationEffect(.degrees(angle))
                .animation(.easeInOut, value: angle)
        }
    }

    var body: some View {
        Group {
            switch displayMode {
            case .preview:
                HStack(spacing: 8.0) {
                    PreviewPill(
                        foreground: foreground,
                        background: background
                    )
                    .allowsHitTesting(false)
                    .zIndex(1)

                    if isVisible {
                        swapButton
                            .buttonStyle(SwapButtonStyle(
                                isVisible: true,
                                alt: PikaText.textColorSwap,
                                ltr: true,
                                expanded: swapHovered,
                                onHoverChange: { swapHovered = $0 }
                            ))
                            .transition(
                                .move(edge: .leading).combined(with: .opacity)
                            )
                    }
                }
                .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.4), value: isVisible)
                .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.4), value: swapHovered)

            case .standalone:
                swapButton
                    .buttonStyle(SwapButtonStyle(
                        isVisible: isVisible,
                        alt: PikaText.textColorSwap,
                        ltr: true
                    ))
            }
        }
        .opacity(fadePhase == .visible ? 1 : 0)
        .onChange(of: showPreview) { _, newValue in
            let targetMode: DisplayMode = newValue ? .preview : .standalone
            guard targetMode != displayMode else { return }

            withAnimation(.easeInOut(duration: 0.2)) {
                fadePhase = .fadingOut
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                displayMode = targetMode
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        fadePhase = .visible
                    }
                }
            }
        }
        .onAppear {
            displayMode = showPreview ? .preview : .standalone
        }
    }
}
