import SwiftUI

struct SwapButtonStyle: ButtonStyle {
    let isVisible: Bool
    let alt: String
    var ltr = false
    var expanded = false
    var onHoverChange: ((Bool) -> Void)?
    /// Called when the label actually appears or goes, which trails the hover by `labelDelay`.
    var onExpandChange: ((Bool) -> Void)?

    /// How long the pointer rests on the button before the first label slides out. Long enough
    /// that passing over a button, or clicking one, doesn't expand it; the label is there for
    /// someone who stops to wonder what the icon does, like a tooltip. Once a label is out, the
    /// others follow after `warmLabelDelay` instead.
    static let labelDelay: Duration = .seconds(1)

    /// Once one button's label is out, the next one follows after this rather than
    /// `labelDelay`, so moving along the buttons reads them off one after another.
    static let warmLabelDelay: Duration = .milliseconds(300)

    /// Whether some icon button's label is showing, or finished hiding within `warmGrace` —
    /// about as long as a label takes to slide away. Shared by every button using this style;
    /// once every label is fully away, the next hover waits the full `labelDelay` again.
    @MainActor private enum LabelWarmth {
        static let warmGrace: TimeInterval = 0.3
        private static var shownCount = 0
        private static var lastHidden = Date.distantPast

        static var delay: Duration {
            shownCount > 0 || Date().timeIntervalSince(lastHidden) < warmGrace ? warmLabelDelay : labelDelay
        }

        static func labelShown() { shownCount += 1 }

        static func labelHidden() {
            shownCount = max(0, shownCount - 1)
            if shownCount == 0 { lastHidden = Date() }
        }
    }

    private struct SwapButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        @State private var isHovered: Bool = false
        @State private var hoverTask: Task<Void, Never>?
        @State private var hoverCooldown: Task<Void, Never>?

        let configuration: Configuration
        let isVisible: Bool
        let alt: String
        let ltr: Bool
        let expanded: Bool
        let onHoverChange: ((Bool) -> Void)?
        let onExpandChange: ((Bool) -> Void)?

        private var showText: Bool { isHovered || expanded }

        var body: some View {
            let fgColor = colorScheme == .dark ? Color.white : .black
            let bgColor = Color.pikaControlBackground(for: colorScheme)

            HStack {
                if ltr {
                    configuration.label
                    if showText {
                        Text(alt)
                            .font(.system(size: 12.0))
                            .padding(.trailing, 2)
                    }
                } else {
                    if showText {
                        Text(alt)
                            .font(.system(size: 12.0))
                            .padding(.leading, 6)
                    }
                    configuration.label
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .mask(RoundedRectangle(cornerRadius: 100.0, style: .continuous))
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 100.0, style: .continuous)
                        .fill(bgColor)
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: configuration.isPressed ? 1 : 2,
                            x: 0,
                            y: configuration.isPressed ? 1 : 2
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 100.0, style: .continuous)
                                .stroke(fgColor.opacity(0.1))
                        )
                }
            )
            .onHover { hover in
                onHoverChange?(hover)
                if hover {
                    guard hoverCooldown == nil, hoverTask == nil else { return }
                    hoverTask = Task {
                        try? await Task.sleep(for: LabelWarmth.delay)
                        guard !Task.isCancelled else { return }
                        isHovered = true
                        hoverTask = nil
                    }
                } else {
                    hoverTask?.cancel()
                    hoverTask = nil
                    isHovered = false
                    hoverCooldown?.cancel()
                    hoverCooldown = Task {
                        try? await Task.sleep(for: .milliseconds(150))
                        guard !Task.isCancelled else { return }
                        hoverCooldown = nil
                    }
                }
            }
            .opacity(isVisible ? (configuration.isPressed ? 0.8 : 1.0) : 0.0)
            .foregroundStyle(fgColor.opacity(0.8))
            .frame(height: 32.0)
            .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.3), value: showText)
            .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.3), value: isVisible)
            .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.3), value: configuration.isPressed)
            .onChange(of: isVisible) { _, visible in
                if !visible {
                    hoverTask?.cancel()
                    hoverTask = nil
                    isHovered = false
                }
            }
            .onChange(of: isHovered) { _, shown in
                if shown { LabelWarmth.labelShown() } else { LabelWarmth.labelHidden() }
                onExpandChange?(shown)
            }
            .onDisappear { if isHovered { LabelWarmth.labelHidden() } }
            // A click answers the question the label was going to: don't expand after it.
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    hoverTask?.cancel()
                    hoverTask = nil
                }
            }
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        SwapButtonStyleView(
            configuration: configuration,
            isVisible: isVisible,
            alt: alt,
            ltr: ltr,
            expanded: expanded,
            onHoverChange: onHoverChange,
            onExpandChange: onExpandChange
        )
    }
}
