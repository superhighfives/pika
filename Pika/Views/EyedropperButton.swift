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

    final class PickTargetView: NSView {
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
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    @Default(.hideColorNames) var hideColorNames
    @Default(.showColorPreview) var showColorPreview
    @Environment(\.pikaAdaptiveVisibility) var adaptive

    @State var hoverVisible: Bool = false
    @State private var colorSpace = Defaults[.colorSpace]
    @State private var hoverTask: Task<Void, Never>?
    @State private var childHovered: Bool = false
    @State private var valueInvalid: Bool = false
    @State private var isPressed: Bool = false
    @State private var flashOpacity: Double = 0
    /// Drives the hairline that shows where the non-picking readout block begins.
    @State private var readoutHovered = false

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
                // Visibility is size-aware (`adaptive.showsTypeLabels` already folds in the
                // preview-pill overlap) so labels fade out as the window shrinks and return
                // when it grows again. The invalid pill overrides the fade so it's never hidden.
                let showsTypeLabel = adaptive.showsTypeLabels
                HStack(alignment: .firstTextBaseline, spacing: 6.0) {
                    Text(eyedropper.type.description)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(eyedropper.color.getUIColor().opacity(0.75))
                    if valueInvalid {
                        InvalidInputPill(uiColor: eyedropper.color.getUIColor())
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
                }
                .opacity(showsTypeLabel || valueInvalid ? 1 : 0)
                .animation(
                    showsTypeLabel
                        ? .easeInOut(duration: 0.25).delay(0.3)
                        : .easeInOut(duration: 0.2),
                    value: showsTypeLabel
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 6.0) {
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

                    if !hideColorNames, adaptive.showsColorNames {
                        Text(eyedropper.getClosestColor())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(eyedropper.color.getUIColor())
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal, 10.0)
            .padding(.bottom, 10.0)
            // Roomier above than below, so the hairline doesn't crowd the type label.
            .padding(.top, 16.0)
            .modify {
                let shadowColor: Color = eyedropper.color.getUIColor() == .white ? .black : .white
                $0
                    .shadow(color: shadowColor.opacity(0.30), radius: 0, x: 0, y: 1)
                    .shadow(color: shadowColor.opacity(0.10), radius: 3, x: 0, y: 0)
            }
            // Both of these sit outside the shadow above, so the hairline stays crisp.
            .background(ClickShield())
            // A single hairline along the top edge, marking where the block stops being a pick
            // target — a full box around the text read as a control it isn't.
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(eyedropper.color.getUIColor()).opacity(readoutHovered ? 0.15 : 0))
                    .frame(height: 1)
                    .allowsHitTesting(false)
            }
            .onHover { readoutHovered = $0 }
            .animation(.easeInOut(duration: 0.15), value: readoutHovered)
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
                        if hover { hoverTask?.cancel(); hoverTask = nil }
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)

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
                        if hover { hoverTask?.cancel(); hoverTask = nil }
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)
            }
            .padding(.all, 8.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            // Subtle affordance for a genuine screen pick landing on this swatch — most useful
            // mid pick-pair, where it's otherwise a silent colour swap with nothing to tell you
            // "that was the foreground" versus "that was the background".
            Color.white
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .onReceive(eyedropper.pickFlash) {
            flashOpacity = 0.35
            withAnimation(.easeOut(duration: 0.35)) {
                flashOpacity = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            colorSpace = Defaults[.colorSpace]
        }
        .onHover { hover in
            if hover {
                hoverTask?.cancel()
                hoverTask = nil
                hoverVisible = true
            } else if hoverTask == nil, !childHovered {
                hoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    hoverVisible = false
                    hoverTask = nil
                }
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
