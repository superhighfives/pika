import SwiftUI

struct SwapButtonStyle: ButtonStyle {
    let isVisible: Bool
    let alt: String
    var ltr = false
    var expanded = false
    var onHoverChange: ((Bool) -> Void)?
    /// Called when the label actually appears or goes, which trails the hover by `labelDelay`.
    var onExpandChange: ((Bool) -> Void)?

    /// How long the pointer rests on a button before its label slides out, the first time.
    /// Long enough that crossing the buttons, or clicking one, doesn't make them expand; the
    /// label is there for someone who stops to wonder what the icon does, like a tooltip. Once
    /// one label has shown, the others show without waiting (see `LabelWarmth`).
    static let labelDelay: Duration = .seconds(1)

    /// How long a label takes to slide back in, matching the `showText` animation below.
    static let labelCollapse: Duration = .milliseconds(300)

    /// The labels that are out, or still sliding back in. While any is, hovering another
    /// button (or the same one again) shows its label with no delay; once every label is back
    /// to its plain icon, the next hover waits the full `labelDelay`. Shared by every button
    /// using this style, so it carries across Copy, the system picker and Swap.
    @MainActor private enum LabelWarmth {
        private static var open: Set<UUID> = []

        static var delay: Duration { open.isEmpty ? labelDelay : .zero }

        static func opened(_ id: UUID) { open.insert(id) }
        static func closed(_ id: UUID) { open.remove(id) }
    }

    private struct SwapButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        @State private var isHovered: Bool = false
        /// This button's identity in `LabelWarmth`'s set of open labels.
        @State private var warmthID = UUID()
        @State private var hoverTask: Task<Void, Never>?
        /// Waits out the label's slide back in before telling `LabelWarmth` it has closed.
        @State private var collapseTask: Task<Void, Never>?

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
                    // Back on while the label is still sliding in: it counts as open, so this
                    // reopens it straight away rather than leaving it shut until you leave and
                    // come back.
                    collapseTask?.cancel()
                    collapseTask = nil
                    guard hoverTask == nil, !isHovered else { return }
                    hoverTask = Task {
                        try? await Task.sleep(for: LabelWarmth.delay)
                        guard !Task.isCancelled else { return }
                        isHovered = true
                        hoverTask = nil
                    }
                } else {
                    hoverTask?.cancel()
                    hoverTask = nil
                    guard isHovered else { return }
                    isHovered = false
                    collapseTask = Task {
                        try? await Task.sleep(for: SwapButtonStyle.labelCollapse)
                        guard !Task.isCancelled else { return }
                        LabelWarmth.closed(warmthID)
                        collapseTask = nil
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
                    collapseTask?.cancel()
                    collapseTask = nil
                    isHovered = false
                    LabelWarmth.closed(warmthID)
                }
            }
            .onChange(of: isHovered) { _, shown in
                if shown { LabelWarmth.opened(warmthID) }
                onExpandChange?(shown)
            }
            .onDisappear {
                collapseTask?.cancel()
                LabelWarmth.closed(warmthID)
            }
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
