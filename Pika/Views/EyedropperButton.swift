import AppKit
import Defaults
import SwiftUI

/// The full-size background pick target: owns its own `mouseDown` (mirroring `ScrubTextField`'s
/// approach in `EditableColorValue.swift`) so it can check the window's first responder *before*
/// deciding what a click means. A plain SwiftUI `Button` can't make that distinction — its action
/// fires unconditionally on tap, so a click intended to dismiss a focused colour-value field would
/// also fall through and start a new pick. If a field is currently being edited, this click's only
/// job is to end that edit (matching standard click-away-to-blur behaviour); otherwise it starts
/// a pick, same as before.
private struct PickTarget: NSViewRepresentable {
    let onPick: () -> Void
    let onPressChange: (Bool) -> Void
    /// Called instead of `onPick` when the click's only job is to end an active edit session.
    /// AppKit's own `endEditing(for:)` resigns the field editor, but doesn't reliably notify
    /// `EditableColorValue`'s own focus-tracking state back up (its outline stays stuck showing
    /// "focused") — so the parent also needs an explicit nudge to clear that state itself.
    let onDismissEditing: () -> Void

    func makeNSView(context _: Context) -> PickTargetView {
        let view = PickTargetView()
        view.onPick = onPick
        view.onPressChange = onPressChange
        view.onDismissEditing = onDismissEditing
        return view
    }

    func updateNSView(_ view: PickTargetView, context _: Context) {
        view.onPick = onPick
        view.onPressChange = onPressChange
        view.onDismissEditing = onDismissEditing
    }

    final class PickTargetView: NSView, EditDismissingClickTarget {
        var onPick: (() -> Void)?
        var onPressChange: ((Bool) -> Void)?
        var onDismissEditing: (() -> Void)?

        override func mouseDown(with _: NSEvent) {
            if window?.firstResponder is NSText {
                window?.endEditing(for: nil)
                onDismissEditing?()
                return
            }

            onPressChange?(true)
            while true {
                guard let next = NSApp.nextEvent(
                    matching: [.leftMouseDragged, .leftMouseUp],
                    until: .distantFuture,
                    inMode: .eventTracking,
                    dequeue: true
                ) else {
                    onPressChange?(false)
                    return
                }
                if next.type == .leftMouseUp {
                    let point = convert(next.locationInWindow, from: nil)
                    onPressChange?(false)
                    if bounds.contains(point) { onPick?() }
                    return
                }
            }
        }
    }
}

/// A view whose own `mouseDown` already ends an active colour-field edit (and needs to see the
/// field still focused to know that's all the click should do), so `EditingClickAway` leaves
/// clicks on it alone.
protocol EditDismissingClickTarget: NSView {}

/// Click-away-to-blur for the colour fields. A click on a swatch already ended an edit (see
/// `PickTarget`), and a click on a button fired the button, but a click anywhere else in the
/// window — the labels, the contrast footer, the title bar — left the field focused. This
/// watches mouse-downs while a field is being edited and ends the edit for any that land
/// outside it. The click itself is never swallowed.
final class EditingClickAway {
    private var monitor: Any?

    func start(onDismiss: @escaping () -> Void) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let window = event.window else { return event }
            // `hitTest` takes a point in the superview's coordinates; the content view's
            // superview is the window's frame view, whose coordinates are the window's.
            let root = window.contentView?.superview ?? window.contentView
            let hit = root?.hitTest(event.locationInWindow)
            if Self.shouldEndEditing(firstResponder: window.firstResponder, clicked: hit) {
                window.endEditing(for: nil)
                onDismiss()
            }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    deinit { stop() }

    /// Whether a mouse-down on `clicked` should end the edit in progress: only when a colour
    /// field is the one being edited, and the click isn't on a colour field (which moves focus
    /// itself) or on a view that ends the edit in its own `mouseDown`.
    static func shouldEndEditing(firstResponder: NSResponder?, clicked: NSView?) -> Bool {
        guard let editor = firstResponder as? NSText, editor.delegate is ScrubTextField else { return false }
        var view = clicked
        while let current = view {
            if current is ScrubTextField || current is EditDismissingClickTarget { return false }
            view = current.superview
        }
        return true
    }
}

/// Swallows clicks over the readout block so they don't fall through to `PickTarget` and start
/// a screen pick. An AppKit view rather than a SwiftUI `contentShape`: `PickTarget` is itself an
/// `NSView` sitting in the same z-order, so the thing shadowing it has to win AppKit's own
/// hit-testing, not just SwiftUI's.
private struct ClickShield: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView { ShieldView() }
    func updateNSView(_: NSView, context _: Context) {}

    final class ShieldView: NSView {
        // Absorb rather than forward: the readout's own fields sit in front of this and keep
        // receiving their clicks, but the labels, colour name, and the gaps between them no
        // longer act as a pick target.
        override func mouseDown(with _: NSEvent) {}
    }
}

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
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
    /// Top of the readout block in the swatch's own coordinates, where the pick area ends.
    @State private var readoutTop: CGFloat = .infinity
    @State private var valueInvalid: Bool = false
    @State private var isPressed: Bool = false
    /// Mirrors `wantsColorName`, but only ever changed inside `withAnimation`. Animating the
    /// environment value directly doesn't work: it changes as part of the geometry pass that
    /// re-evaluates the whole tree, and `.animation(_:value:)` doesn't catch that — the row just
    /// snapped to full height. Driving an explicit state change is what makes it a transition.
    @State private var colorNameVisible = false

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
            .background(Color(eyedropper.color))
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeIn(duration: 0.15), value: Color(eyedropper.color))
            .animation(.easeIn(duration: 0.15), value: isPressed)

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
                    // Trailing gutter keeps the value clear of the copy / system-picker hover
                    // buttons; the value shrinks to fit as its column narrows.
                    EditableColorValue(
                        eyedropper: eyedropper,
                        format: colorFormat,
                        style: copyFormat,
                        colorSpace: colorSpace,
                        availableWidth: adaptive.swatchWidth,
                        isInvalid: $valueInvalid,
                        dismissEditingTrigger: dismissEditingTrigger
                    )
                    .padding(.trailing, 32.0)

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
            .padding(.horizontal, 10.0)
            .padding(.bottom, 10.0)
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

            VStack(spacing: 4.0) {
                Button(action: {
                    NSApp.sendAction(eyedropper.type.copySelector, to: nil, from: nil)
                }, label: {
                    IconImage(name: "doc.on.doc", resizable: true)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                })
                .buttonStyle(SwapButtonStyle(
                    isVisible: hoverVisible,
                    alt: PikaText.textColorCopy,
                    onHoverChange: { hover in
                        childHovered = hover
                        updateButtonVisibility()
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)
                // The style only draws `alt` on hover; the label itself is a bare SF Symbol.
                .accessibilityLabel(PikaText.textColorCopy)

                Button(action: {
                    NSApp.sendAction(eyedropper.type.systemPickerSelector, to: nil, from: nil)
                }, label: {
                    IconImage(name: "paintpalette", resizable: true)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                })
                .buttonStyle(SwapButtonStyle(
                    isVisible: hoverVisible,
                    alt: PikaText.textColorSystemPicker,
                    onHoverChange: { hover in
                        childHovered = hover
                        updateButtonVisibility()
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)
                // The style only draws `alt` on hover; the label itself is a bare SF Symbol.
                .accessibilityLabel(PikaText.textColorSystemPicker)
            }
            .padding(.all, 8.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            colorSpace = Defaults[.colorSpace]
        }
        .coordinateSpace(name: Self.swatchSpace)
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
            if inReadout != readoutHovered {
                readoutHovered = inReadout
                updateButtonVisibility()
            }
            onPickAreaHover(inPickArea)
        }
    }

    private static let swatchSpace = "swatch"

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

struct EyedropperButton_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperButton(
            eyedropper: Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!),
            dismissEditingTrigger: .constant(0)
        )
        .frame(width: 170.0)
    }
}
