import AppKit
import Defaults
import SwiftUI

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
    @EnvironmentObject var eyedroppers: Eyedroppers
    /// Shared with the other swatch (owned by `ColorPickers`) rather than local: a click on
    /// *this* swatch's `PickTarget` can be dismissing a field focused on the *other* swatch,
    /// since the first-responder check that decides "dismiss vs. pick" is window-wide, not
    /// scoped to this button. Bumping a trigger only this button's own `EditableColorValue`
    /// hears would silently drop that edit instead of committing or reverting it.
    @Binding var dismissEditingTrigger: Int
    /// Height to hold the readout block at — the taller of the two swatches', resolved by
    /// `ColorPickers`, so the boundary sits at one height across the pair. 0 until measured.
    var readoutHeight: CGFloat = 0
    /// Driven by hovering either swatch, so both boundaries show together.
    var showsReadoutBoundary: Bool = false
    /// Reports whether the pointer is over the pick area: the swatch above the readout block.
    /// The Swap button shows only while one of the two pick areas is hovered.
    var onPickAreaHover: (Bool) -> Void = { _ in }
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    @Default(.hideColorNames) var hideColorNames
    @Default(.showColorPreview) var showColorPreview
    @Environment(\.pikaAdaptiveVisibility) var adaptive

    @State var hoverVisible: Bool = false
    @State private var colorSpace = Defaults[.colorSpace]
    @State private var hoverTask: Task<Void, Never>?
    @State private var childHovered: Bool = false
    /// Whether the pointer is over the readout block (below the hairline). The Copy and system
    /// picker buttons belong to the readout, so they show only while it, or they, are hovered.
    @State private var readoutHovered: Bool = false
    /// Whether the pointer is over the pick area (above the hairline), so `onPickAreaHover`
    /// fires on a change rather than on every pointer move.
    @State private var pickAreaHovered: Bool = false
    /// Top of the readout block in the swatch's own coordinates, where the pick area ends.
    @State private var readoutTop: CGFloat = .infinity
    @State private var valueInvalid: Bool = false
    @State private var isPressed: Bool = false
    /// Mirrors `wantsColorName`, but only ever changed inside `withAnimation`. Animating the
    /// environment value directly doesn't work: it changes as part of the geometry pass that
    /// re-evaluates the whole tree, and `.animation(_:value:)` doesn't catch that — the row just
    /// snapped to full height. Driving an explicit state change is what makes it a transition.
    @State private var colorNameVisible = false
    /// `adaptive.showsPreview` and `adaptive.bottomInset`, changed inside `withAnimation` for
    /// the same reason as `colorNameVisible`: from the environment they snapped into place.
    @State private var previewShown = false
    @State private var bottomInset: CGFloat = 0

    private var wantsColorName: Bool { !hideColorNames && adaptive.showsColorNames }

    private let colorNameFontSize: CGFloat = 12
    /// Gap between the value and the colour name, carried by the name's own row so it
    /// collapses along with it.
    private static let colorNameSpacing: CGFloat = 6
    /// The height that row occupies when shown: one line of its own font, plus that gap.
    /// Measured from the font rather than hard-coded so it tracks the text it's reserving for.
    private var colorNameRowHeight: CGFloat {
        let font = NSFont.systemFont(ofSize: colorNameFontSize, weight: .medium)
        return ceil(font.ascender - font.descender + font.leading) + Self.colorNameSpacing
    }

    var body: some View {
        ZStack {
            // Background pick target: a click anywhere that isn't the editable value (or the
            // non-interactive labels above it, which fall through) starts a pick — unless a
            // colour-value field is currently focused, in which case it just dismisses that
            // field. See `PickTarget` above.
            PickTarget(
                onPick: { NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil) },
                onPressChange: { isPressed = $0 },
                onDismissEditing: { dismissEditingTrigger += 1 }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .eyedropperPointer()
            .background(Color(eyedropper.color))
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeIn(duration: 0.15), value: Color(eyedropper.color))
            .animation(.easeIn(duration: 0.15), value: isPressed)

            // The other colour set as text on this one, so the pair reads both ways round.
            // Not hit-testable: a click here still picks.
            if previewShown {
                SwatchPreview(
                    other: eyedropper.type == .foreground ? eyedroppers.background : eyedroppers.foreground
                )
                .padding(.horizontal, 10.0)
                .padding(.top, 14.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Content overlay, lifted out of the pick button so the value's fields receive
            // clicks. The type label and colour name disable hit-testing so clicks fall
            // through to the pick button behind them.
            VStack(alignment: .leading, spacing: 2.0) {
                // `adaptive.showsTypeLabels` is hardcoded `true` (ContentView.swift) as of
                // `81fe9f9`, so the fade below is currently vestigial — kept in case that's
                // revisited, rather than stripped along with the conditional that once drove it.
                // The invalid pill overrides the fade so it's never hidden.
                let showsTypeLabel = adaptive.showsTypeLabels
                HStack(alignment: .firstTextBaseline, spacing: 6.0) {
                    Text(eyedropper.type.description)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(eyedropper.color.getUIColor().opacity(0.75))
                        .allowsHitTesting(false)
                    if valueInvalid {
                        InvalidInputPill(uiColor: eyedropper.color.getUIColor())
                            .allowsHitTesting(false)
                    } else if !eyedropper.color.isDisplayable(in: .current) {
                        // Hit-testable, unlike the rest of this row, so its tooltip can show.
                        OutOfGamutIndicator(uiColor: eyedropper.color.getUIColor())
                    }
                    // Reserves the pill's height in this row at all times (zero width, so it
                    // never otherwise affects layout) so toggling the pill doesn't change the
                    // row's height. The content below is anchored `.bottomLeading` in its parent
                    // frame, so any height change here shifts this label — the "Foreground" /
                    // "Background" text visibly jumping by a pixel each time invalid state was
                    // entered or exited.
                    InvalidInputPill(uiColor: .clear)
                        .fixedSize()
                        .frame(width: 0)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                    if !iconsInline {
                        Spacer(minLength: 0)
                        actionIcons
                    }
                }
                .opacity(showsTypeLabel || valueInvalid ? 1 : 0)
                .animation(
                    showsTypeLabel
                        ? .easeInOut(duration: 0.25).delay(0.3)
                        : .easeInOut(duration: 0.2),
                    value: showsTypeLabel
                )

                // Spacing 0, with the gap above the colour name carried by that row's own
                // height: the name has to be able to collapse to nothing, and a `VStack`
                // spacing would still be contributing 6pt when it did.
                VStack(alignment: .leading, spacing: 0) {
                    // The quiet Copy, Pick and ⋯ icons follow the value on its row. The value
                    // shrinks and wraps to fit what's left of the column after them.
                    EditableColorValue(
                        eyedropper: eyedropper,
                        format: colorFormat,
                        style: copyFormat,
                        colorSpace: colorSpace,
                        availableWidth: adaptive.swatchWidth,
                        isInvalid: $valueInvalid,
                        dismissEditingTrigger: dismissEditingTrigger,
                        trailingAccessory: iconsInline ? AnyView(actionIcons) : nil,
                        accessoryWidth: iconsInline ? Self.actionIconsWidth : 0
                    )

                    // Always in the hierarchy, collapsing to zero height rather than being
                    // inserted and removed. This block is bottom-anchored, so a row appearing
                    // at full height shoves everything above it up by that much in a single
                    // frame — the jump you see when the colour name arrives. Animating the
                    // height (and fading in) turns that into a reveal instead.
                    Text(eyedropper.getClosestColor())
                        .font(.system(size: colorNameFontSize, weight: .medium))
                        .foregroundStyle(eyedropper.color.getUIColor())
                        .allowsHitTesting(false)
                        .padding(.top, Self.colorNameSpacing)
                        .frame(height: colorNameVisible ? colorNameRowHeight : 0, alignment: .top)
                        .opacity(colorNameVisible ? 1 : 0)
                        .clipped()
                }
                .onAppear { colorNameVisible = wantsColorName }
                .onChange(of: wantsColorName) { shows in
                    withAnimation(.easeInOut(duration: 0.2)) { colorNameVisible = shows }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10.0)
            .padding(.bottom, 10.0 + bottomInset)
            // Roomier above than below, so the hairline doesn't crowd the type label.
            .padding(.top, 16.0)
            // Measured *before* the shared height is imposed below, so this reports what the
            // block naturally wants and can't feed back into its own answer.
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ReadoutHeightKey.self, value: geo.size.height)
                }
            )
            // Both swatches take the taller one's height, so the shield and the hairline that
            // marks its edge line up across the pair even when one value wraps and the other
            // doesn't. Bottom-aligned, so the extra height opens upward and the readout itself
            // stays put.
            .frame(height: readoutHeight > 0 ? readoutHeight : nil, alignment: .bottom)
            .modify {
                let shadowColor: Color = eyedropper.color.getUIColor() == .white ? .black : .white
                $0
                    .shadow(color: shadowColor.opacity(0.30), radius: 0, x: 0, y: 1)
                    .shadow(color: shadowColor.opacity(0.10), radius: 3, x: 0, y: 0)
            }
            // Both of these sit outside the shadow above, so the hairline stays crisp.
            .background(ClickShield())
            .defaultPointer()
            .background(
                GeometryReader { geo in
                    let top = geo.frame(in: .named(Self.swatchSpace)).minY
                    Color.clear
                        .onAppear { readoutTop = top }
                        .onChange(of: top) { readoutTop = $0 }
                }
            )
            // A single hairline along the top edge, marking where the block stops being a pick
            // target — a full box around the text read as a control it isn't.
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(eyedropper.color.getUIColor()).opacity(showsReadoutBoundary ? 0.15 : 0))
                    .frame(height: 1)
                    .allowsHitTesting(false)
            }
            .animation(.easeInOut(duration: 0.15), value: showsReadoutBoundary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            colorSpace = Defaults[.colorSpace]
        }
        .onAppear {
            previewShown = adaptive.showsPreview
            bottomInset = adaptive.bottomInset
        }
        .onChange(of: adaptive.showsPreview) { shows in
            withAnimation(.easeInOut(duration: 0.25)) { previewShown = shows }
        }
        .onChange(of: adaptive.bottomInset) { inset in
            withAnimation(.easeInOut(duration: 0.2)) { bottomInset = inset }
        }
        .coordinateSpace(name: Self.swatchSpace)
        .contextMenu { SwatchActionsMenu(eyedropper: eyedropper) }
        .onContinuousHover(coordinateSpace: .named(Self.swatchSpace)) { phase in
            let inReadout: Bool
            let inPickArea: Bool
            switch phase {
            case let .active(location):
                inReadout = location.y >= readoutTop
                inPickArea = !inReadout
            case .ended:
                inReadout = false
                inPickArea = false
            }
            // The icons show while anywhere on the colour is hovered.
            let inSwatch = inReadout || inPickArea
            if inSwatch != readoutHovered {
                readoutHovered = inSwatch
                updateButtonVisibility()
            }
            if inPickArea != pickAreaHovered {
                pickAreaHovered = inPickArea
                onPickAreaHover(inPickArea)
                // The eyedropper is the pick area's only affordance. Pushed and popped with the
                // hover, since SwiftUI's hosting view resets a cursor merely set from AppKit.
                if #unavailable(macOS 15) {
                    if inPickArea { EyedropperCursor.shared.push() } else { NSCursor.pop() }
                }
            }
        }
    }

    private static let swatchSpace = "swatch"

    /// Whether the icons fit after the value. In a narrow colour, reserving their room would
    /// shrink the value, so they move to the end of the type label's row instead.
    private var iconsInline: Bool { adaptive.swatchWidth >= 250 }

    private var actionIcons: some View {
        SwatchActionIcons(
            eyedropper: eyedropper,
            isVisible: hoverVisible,
            onHoverChange: { hover in
                childHovered = hover
                updateButtonVisibility()
            }
        )
    }

    /// Room the Copy, Pick and ⋯ icons take after the value: three 18pt icons, the gaps
    /// between them and the gap before them.
    private static let actionIconsWidth: CGFloat = 3 * 18 + 2 * 10 + 10

    /// Shows the Copy and system picker buttons while the readout or the buttons are hovered,
    /// and hides them a moment after neither is, so crossing the gap onto a button doesn't
    /// flicker them away.
    private func updateButtonVisibility() {
        if readoutHovered || childHovered {
            hoverTask?.cancel()
            hoverTask = nil
            hoverVisible = true
        } else if hoverTask == nil {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                if !readoutHovered, !childHovered { hoverVisible = false }
                hoverTask = nil
            }
        }
    }
}

/// "Aa" and a line of sample text in the other swatch's colour, drawn on this one.
private struct SwatchPreview: View {
    @ObservedObject var other: Eyedropper

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text("Aa")
                .font(.system(size: 34, weight: .bold))
            Text(Self.sampleText)
                .font(.system(size: 13))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color(other.color))
        .accessibilityHidden(true)
    }

    /// The sample sentence broken over two lines at the space nearest its middle, so it reads
    /// as a short block rather than one long line. Languages without spaces wrap as they fall.
    static let sampleText: String = {
        let sample = NSLocalizedString("color.preview.sample", comment: "Sample preview text")
        let middle = sample.index(sample.startIndex, offsetBy: sample.count / 2)
        let spaces = sample.indices.filter { sample[$0] == " " }
        guard let split = spaces.min(by: {
            abs(sample.distance(from: $0, to: middle)) < abs(sample.distance(from: $1, to: middle))
        }) else { return sample }
        return sample.replacingCharacters(in: split ... split, with: "\n")
    }()
}

struct EyedropperButton_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperButton(
            eyedropper: Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!),
            dismissEditingTrigger: .constant(0)
        )
        .frame(width: 170.0)
    }
}
