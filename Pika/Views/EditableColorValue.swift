import AppKit
import Defaults
import SwiftUI

/// The "⚠ Invalid input" pill shown beside the type label while a focused field holds
/// unparseable input. Coloured to the swatch's UI text colour so it reads on any background.
struct InvalidInputPill: View {
    let uiColor: NSColor

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(PikaText.textColorEditInvalid)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(Color(uiColor))
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(Capsule().fill(Color(uiColor).opacity(0.18)))
    }
}

/// Units nudged per pixel of drag/scroll (or per arrow-key press), scaled to a component's own
/// range so every field's full span takes about the same drag distance to traverse — hue's
/// `0...360` (which felt right at a flat 1 unit/px) is the reference; without this, OKLCH
/// chroma's `0...1` range would swing end-to-end in a single pixel. Unranged components (e.g.
/// Lab a/b) fall back to the flat 1 unit/px, having no span to scale against.
let dragSensitivityReferenceSpan: Double = 360

func dragUnitsPerPixel(for range: ClosedRange<Double>?) -> Double {
    guard let range else { return 1.0 }
    return (range.upperBound - range.lowerBound) / dragSensitivityReferenceSpan
}

/// The editable colour readout. Fixed format scaffolding renders as dimmed, non-editable text;
/// each numeric component is a focusable field. Valid edits preview live on `eyedropper` (which
/// posts nothing, so history stays quiet); Enter or a valid blur commits — recording history once
/// via `.colorPicked` — while Escape or an invalid blur reverts to the pre-edit colour.
struct EditableColorValue: View {
    @ObservedObject var eyedropper: Eyedropper
    let format: ColorFormat
    let style: CopyFormat
    let colorSpace: NSColorSpace
    /// Width of this swatch (half the window's content width), read from `ContentView`'s own
    /// outer `GeometryReader` via `PikaAdaptiveVisibility.swatchWidth` and threaded down through
    /// `EyedropperButton`. Not measured again here or in `EyedropperButton`: a `GeometryReader`/
    /// preference round trip placed lower in the tree — around this view's own `FlowLayout`, and
    /// separately around `PickTarget`'s frame — was found in both cases to never fire past its
    /// initial zero value, so the row's width fell back to an ambiguous `.frame(maxWidth: .infinity)`
    /// that was itself sometimes only ever queried for its ideal size, never wrapping.
    let availableWidth: CGFloat
    /// Raised while the focused field holds unparseable input, so the parent can show the pill.
    @Binding var isInvalid: Bool
    /// Bumped by the parent to end any active edit session (e.g. a click landing elsewhere in the
    /// swatch that's meant to dismiss a focused field rather than act on it). Driving this
    /// straight through `focusedIndex` rather than via AppKit's responder chain (e.g.
    /// `window.endEditing(for:)`) matters: that resigns the field editor, but `ScrubTextField`'s
    /// own `resignFirstResponder` override — the thing that actually reports the blur back up
    /// via `onFocusChange` — doesn't reliably fire for it, leaving this view's local state (and
    /// its focus outline) stuck showing "focused" even once AppKit itself has moved on.
    var dismissEditingTrigger: Int = 0

    private let baseSize: CGFloat = 18
    private let minSize: CGFloat = 11

    /// Identifies which (format, style, colorSpace) a cached `values` array was decomposed for,
    /// so a format/style switch — or a display colour-space switch in Preferences, which changes
    /// `decompose`'s output just as much — is detected even when the component count doesn't
    /// change (every non-hex format always has exactly 3 components).
    private struct FormatStyleKey: Equatable {
        let format: ColorFormat
        let style: CopyFormat
        let colorSpace: NSColorSpace
    }

    /// The outer VStack's `.padding(.all, 10)` plus the trailing gutter this view is given at
    /// its call site (`.padding(.trailing, 32)`, reserved for the copy/system-picker hover
    /// buttons) — both applied *outside* this view, so `availableWidth` (measured at the swatch
    /// content's outer edge) has to have them subtracted back out here.
    private let horizontalInset: CGFloat = 52
    private var effectiveWidth: CGFloat { max(availableWidth - horizontalInset, 0) }

    /// Working component strings. Kept in sync with the colour when idle; owned by the user
    /// while a field is focused.
    @State private var values: [String] = []
    @State private var valuesKey: FormatStyleKey?
    @State private var isEditing = false
    /// Font size pinned for the duration of a session, so scrubbing (which changes the value's
    /// digit count, and so its rendered width, on essentially every frame) doesn't repeatedly
    /// re-shrink/re-wrap the row — the flicker that made the value visibly flick between one and
    /// two lines while dragging. Captured once at session start, cleared once it ends.
    @State private var frozenSize: CGFloat?
    @State private var preEditColor: NSColor?
    /// The colour we last pushed to `eyedropper` ourselves (live preview or commit). Lets
    /// `onChange(of: eyedropper.color)` tell our own writes apart from an external pick landing
    /// mid-edit, so the latter can abort the session instead of being silently overwritten.
    @State private var lastPreviewedColor: NSColor?
    /// Plain `@State`, not `@FocusState`: nothing here is bound via `.focused()` to an actual
    /// SwiftUI-focusable view (the field is a raw AppKit `NSTextField`, focus is driven by hand
    /// through `ColorComponentField`'s `onFocusChange`). `@FocusState` expects to reconcile
    /// against the real focus environment and would get silently reset to `nil` by unrelated
    /// window/focus churn — e.g. a sibling's hover state changing — dropping the outline and
    /// ending the edit the moment the mouse left the field, even mid-session.
    @State private var focusedIndex: Int?
    /// Which field the currently-open session (if any) belongs to — always non-nil whenever
    /// `isEditing` is true, kept in sync with `focusedIndex` whenever focus moves but, unlike
    /// `focusedIndex`, also set for a fresh unfocused scrub session (drag/scroll deliberately
    /// never focuses the real field — see `beginDragSession`'s comment). Exists so a scrub
    /// session's end — `onDragEnd`, which for scroll-to-scrub can arrive late via trailing
    /// trackpad momentum — can tell "this is still my session" apart from "a different field
    /// has since taken over, or this session already ended and a new one started elsewhere."
    @State private var sessionOwner: Int?
    /// The component values as they were when the session began, kept pristine for its whole
    /// duration. Every scrub frame recomposes from *these* rather than from `values`, which now
    /// tracks the clamped colour: feeding each frame's clamped result back in would make the drag
    /// path-dependent, ratcheting the untouched components a little further every frame so
    /// dragging back where you came from no longer returns the colour you started with.
    @State private var sessionStartValues: [String] = []
    /// The whole colour, formatted, while a scrub is in flight — shown in one pill above the row.
    /// Every field's text stays frozen for the gesture: syncing the untouched components live
    /// would change *their* widths instead, which moves `FlowLayout`'s wrap point just as surely
    /// as the dragged one did. Showing the complete value here keeps the readout honest without
    /// anything in the row itself changing size.
    @State private var rowScrubPreview: String?
    /// True for the duration of a click-drag/scroll scrub. A scrub deliberately resigns first
    /// responder (so no caret or selection shows over a value you're dragging), and that blur
    /// must not be mistaken for a tab-out that should commit and close the session.
    @State private var isScrubbing = false

    private var decomposed: DecomposedColor {
        format.decompose(eyedropper.color, style: style, in: colorSpace)
    }

    private var uiColor: NSColor { eyedropper.color.getUIColor() }

    /// `FlowLayout` should never need more than this many lines.
    private let maxLines: CGFloat = 2
    /// Shrink target, deliberately less than `maxLines`: wrapping happens at fragment boundaries,
    /// not the halfway character, so a greedy 2-line wrap rarely splits content 50/50 — leave
    /// slack instead of clipping the fuller line.
    private let wrapShrinkTarget: CGFloat = 1.7

    // Deterministic font size vs `wrapShrinkTarget` rows of column width, so the row shrinks
    // just enough that `FlowLayout` wraps to at most `maxLines`.
    private func fontSize(for text: String) -> CGFloat {
        guard effectiveWidth > 4 else { return baseSize }
        let full = (text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: baseSize)]).width
        guard full > 0 else { return baseSize }
        let scale = min(1, (effectiveWidth * wrapShrinkTarget) / full)
        return max(minSize, baseSize * scale)
    }

    var body: some View {
        let layout = decomposed
        let size = frozenSize ?? fontSize(for: layout.joined())

        FlowLayout(maxLines: Int(maxLines)) {
            affix(layout.leading, size: size)
            ForEach(Array(layout.components.enumerated()), id: \.offset) { index, component in
                // Grouped with its trailing punctuation (the separator after it, or the closing
                // affix for the last one) into one atomic wrap unit — otherwise `FlowLayout`
                // could wrap that punctuation onto the next line by itself, orphaned ahead of
                // the value it actually belongs to.
                HStack(spacing: 0) {
                    ColorComponentField(
                        text: binding(for: index, layout: layout),
                        component: component,
                        index: index,
                        uiColor: uiColor,
                        fontSize: size,
                        focusedIndex: $focusedIndex,
                        onSubmit: commitEditing,
                        onCancel: revertEditing,
                        onDragBegin: { beginDragSession(index: index, layout: layout) },
                        onDragEnd: { finishDragOrScrollSession(index: index) },
                        onLiveValue: { value, places in
                            previewLiveScrub(index: index, layout: layout, value: value, decimals: places)
                        }
                    )
                    if index < layout.separators.count {
                        affix(layout.separators[index], size: size)
                    } else {
                        affix(layout.trailing, size: size)
                    }
                }
            }
        }
        // Decorative overlay: it doesn't feed into the row's reported size, so it can appear and
        // change width without perturbing `FlowLayout`. Anchored to the row rather than to the
        // dragged field, so it's always in bounds and doesn't jump between components.
        .overlay(alignment: .topLeading) {
            if let rowScrubPreview {
                Text(rowScrubPreview)
                    // Monospaced so the digits hold their columns: at a proportional width the
                    // numbers jitter sideways on every frame of a drag, which is exactly the
                    // distraction the pill exists to avoid.
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Color(uiColor == .white ? .black : .white))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(uiColor).opacity(0.92)))
                    .frame(maxWidth: effectiveWidth, alignment: .leading)
                    // The swatch's content carries a text shadow for legibility on any colour;
                    // inherited by the pill it just reads as blur, so cancel it here.
                    .shadow(color: .clear, radius: 0, x: 0, y: 0)
                    .offset(y: -24)
                    .allowsHitTesting(false)
            }
        }
        // An explicit width, not `.frame(maxWidth: .infinity)`: a plain flexible frame was found
        // to sometimes only ever be queried for its *ideal* size in this view's position in the
        // hierarchy, never its true constrained size, so `FlowLayout` never wrapped and the row
        // silently overflowed past the window edge instead. `availableWidth` comes from
        // `ContentView`'s own outer `GeometryReader` (see its doc comment), so it's already
        // non-zero on this view's very first render — no separate zero-width bootstrap state
        // to fall back from.
        .frame(width: effectiveWidth, alignment: .leading)
        .onAppear { syncValuesFromColor(layout) }
        .onChange(of: focusedIndex) { newValue in handleFocusChange(to: newValue, layout: layout) }
        .onChange(of: eyedropper.color) { newValue in
            if isEditing {
                // A change we didn't push ourselves is an external pick landing mid-edit —
                // abort the session so the external colour wins, matching pre-edit behaviour.
                if newValue != lastPreviewedColor { abortEditingForExternalPick() }
            } else if newValue != lastPreviewedColor {
                // Only resync from a colour we didn't just set ourselves. Without this check,
                // this handler fires right after our own commit lands (isEditing has already
                // flipped false by then) and undoes finishEditing's deliberate `resync: false` —
                // e.g. snapping a just-typed hue back to 0 once brightness/saturation round-trips
                // it through a colour where hue is undefined.
                syncValuesFromColor(decomposed)
            }
        }
        .onChange(of: format) { _ in handleFormatOrStyleChange() }
        .onChange(of: style) { _ in handleFormatOrStyleChange() }
        .onChange(of: colorSpace) { _ in handleFormatOrStyleChange() }
        .onChange(of: dismissEditingTrigger) { _ in focusedIndex = nil }
    }

    private func affix(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(Color(uiColor).opacity(0.5))
            .lineLimit(1)
    }

    // MARK: - Values ↔ colour

    private func syncValuesFromColor(_ layout: DecomposedColor) {
        values = layout.values
        valuesKey = FormatStyleKey(format: format, style: style, colorSpace: colorSpace)
    }

    private func binding(for index: Int, layout: DecomposedColor) -> Binding<String> {
        let currentKey = FormatStyleKey(format: format, style: style, colorSpace: colorSpace)
        return Binding(
            get: {
                guard valuesKey == currentKey, index < values.count else { return layout.values[index] }
                return values[index]
            },
            set: { newValue in
                if valuesKey != currentKey || values.count != layout.components.count {
                    values = layout.values
                    valuesKey = currentKey
                }
                guard index < values.count else { return }
                values[index] = newValue
                previewIfValid(layout: layout)
            }
        )
    }

    // MARK: - Editing lifecycle

    /// A format, copy-style, or display colour-space switch changes how the same colour is
    /// *displayed*, not the colour itself. Mid-edit, the typed values are in the old units and
    /// can't be reinterpreted safely, so abort the session rather than risk a bogus commit;
    /// otherwise just resync.
    private func handleFormatOrStyleChange() {
        if isEditing {
            abortEditingForExternalPick()
        } else {
            syncValuesFromColor(decomposed)
        }
    }

    /// Starting a drag on a field that isn't the one currently owning the edit session (if any)
    /// joins that session by moving focus to it, the same way clicking a new field mid-edit does
    /// in `handleFocusChange` — rather than letting a second, session-less drag mutate the shared
    /// `values` array and then tear down the first field's session on release.
    ///
    /// A *fresh* session deliberately does NOT set `focusedIndex`: scrubbing (drag or scroll)
    /// must never focus the real `TextField`, or its AppKit field editor becomes first responder
    /// and fights the scrub with click-to-edit/select-all behaviour. An unfocused `TextField`
    /// with a changing `text` binding just renders like a label — no editor involved.
    private func beginDragSession(index: Int, layout: DecomposedColor) {
        sessionOwner = index
        isScrubbing = true
        if isEditing {
            focusedIndex = index
            return
        }
        startSession(layout: layout)
    }

    private func handleFocusChange(to newValue: Int?, layout: DecomposedColor) {
        if let newValue {
            // Entering (or moving between) fields — start a session on the first focus, or
            // (per the comment on `sessionOwner`) take over an existing unfocused scrub session.
            sessionOwner = newValue
            if !isEditing {
                startSession(layout: layout)
            }
        } else if isEditing, !isScrubbing {
            // Focus left every field (blur / tab-out) — commit if valid, otherwise revert.
            // Not during a scrub: that blur is one we asked for, not the user leaving the field.
            finishEditing()
        }
    }

    /// `onDragEnd` for click-drag scrub is driven by a synchronous, blocking event-tracking loop
    /// (`ScrubTextField.mouseDown`), so it can never fire late — nothing else can run until it
    /// returns. Scroll-to-scrub's end can, though: trailing trackpad momentum can deliver
    /// `onScrollEnd` well after a different field has taken over the session (a plain click
    /// focusing it, or a fresh drag/scroll on it), or after this session already ended and a new
    /// one started elsewhere. Only finish if `index` is still the session's current owner.
    private func finishDragOrScrollSession(index: Int) {
        guard isEditing, sessionOwner == index else { return }
        rowScrubPreview = nil
        isScrubbing = false
        finishEditing()
        // A scrub's committed colour is the clamped, displayable one, which may not decompose
        // back to exactly the values that produced it. Resync the whole readout from the real
        // colour so what's shown is what's on screen — otherwise the next interaction resyncs
        // instead, and the values appear to change on their own.
        syncValuesFromColor(decomposed)
        // AppKit implicitly focuses (and select-alls) a field as part of routing the mouseDown
        // that turns out to be a click-drag (see `ScrubTextField.beginDrag`'s comment) —
        // regardless of whether the drag started fresh or on an already-focused field. A scrub
        // must never leave the field looking like an active text edit once it's done (the
        // "renders like a label" intent documented on `beginDragSession` above); `finishEditing`/
        // `endSession` only manage `isEditing`, not `focusedIndex`. Clearing it here — rather
        // than resigning first responder directly from AppKit — routes through the same
        // `updateNSView` reconciliation (`isFocused`/`editorIsActive`) that already reliably
        // drives real focus changes elsewhere, instead of depending on `resignFirstResponder`
        // firing for a resign that didn't originate from `self` becoming first responder, which
        // proved unreliable (see `PickTarget`'s `dismissEditingTrigger`).
        if focusedIndex == index {
            focusedIndex = nil
        }
    }

    /// Snapshot the colour and working values at the start of an edit or drag session, so
    /// `finishEditing`/`abortEditingForExternalPick` have a consistent point to commit or revert to.
    private func startSession(layout: DecomposedColor) {
        isEditing = true
        sessionStartValues = layout.values
        // The size the value is *already* being shown at. Sizing to the format's theoretical
        // widest value instead made the whole readout collapse to `minSize` the instant you
        // clicked it in a narrow window — a jarring shrink, and the reason it's not done here.
        // Nothing in the row changes width mid-scrub any more (every field's text is frozen and
        // the live value goes to the pill), so there's no drift left to size defensively against.
        frozenSize = fontSize(for: layout.joined())
        preEditColor = eyedropper.color
        values = layout.values
        valuesKey = FormatStyleKey(format: format, style: style, colorSpace: colorSpace)
    }

    /// Recompose the working values and preview them live; flag invalid input for the pill.
    private func previewIfValid(layout: DecomposedColor) {
        let allValid = zip(layout.components, values).allSatisfy { $0.isValid($1) }
        isInvalid = !allValid
        guard allValid, let color = format.recompose(values, style: style, in: colorSpace) else { return }
        eyedropper.set(color)
        lastPreviewedColor = eyedropper.color
    }

    /// Returns the value actually achieved — which is not always the one requested. Lab/OKLCH can
    /// express colours outside sRGB, and `recompose` clamps those to the nearest displayable
    /// channel (see `NSColor.encodeSRGB`), so e.g. `oklch(30% 0.2 230)` really lands on chroma
    /// ~0.137. Reading the value back off the resulting colour means the readout can only ever
    /// show a colour the screen can genuinely produce: a drag past the gamut boundary simply
    /// stops there instead of displaying a number that silently disagrees with the swatch (and
    /// then appearing to "jump" when a later interaction resynced from the real colour).
    @discardableResult
    private func previewLiveScrub(index: Int, layout: DecomposedColor, value: Double, decimals: Int) -> Double {
        guard index < layout.components.count else { return value }
        // From the session's starting values, never the live (clamped) ones — see
        // `sessionStartValues`. This is what makes a scrub reversible: drag chroma up into the
        // clamped region and back down, and you land on exactly the colour you began with.
        var liveValues = sessionStartValues.count == layout.components.count ? sessionStartValues : layout.values
        guard index < liveValues.count else { return value }
        liveValues[index] = ColorComponentField.formattedDragValue(value, kind: layout.components[index].kind)
        guard let color = format.recompose(liveValues, style: style, in: colorSpace) else { return value }
        eyedropper.set(color)
        lastPreviewedColor = eyedropper.color
        // Round-trip the committed colour back through `decompose` to see what it actually
        // became. Clamping doesn't only move the dragged component — pushing chroma out of gamut
        // shifts the resulting colour's lightness and hue too — so resync every *other* component
        // from the real colour. Without this the readout contradicts the swatch (a magenta swatch
        // still showing a blue hue), and worse, the commit would pair the dragged component's new
        // value with the others' stale ones and land on a third colour entirely.
        //
        // The dragged component itself is deliberately left alone: its text stays frozen for the
        // gesture so the row can't reflow, and the pill shows its live value instead.
        let achieved = format.decompose(color, style: style, in: colorSpace)
        guard index < achieved.components.count,
              let effective = Double(achieved.components[index].value.trimmingCharacters(in: .whitespaces))
        else {
            return value
        }
        // Just the numbers — the `oklch(`/`)` scaffolding is already right there in the row
        // beneath, so repeating it in the pill is noise. The dragged component renders at the
        // scrub's own precision (what vertical travel is adjusting); the rest show as decomposed.
        var preview = ""
        for (position, component) in achieved.components.enumerated() {
            preview += position == index
                ? ColorComponentField.formattedDragValue(effective, kind: component.kind, stableDecimalPlaces: decimals)
                : component.value
            if position < achieved.separators.count { preview += achieved.separators[position] }
        }
        rowScrubPreview = preview
        return effective
    }

    /// Snaps any component whose typed value fell outside its range to the nearest bound, and
    /// restrips every numeric value's trailing zeros back to its normal compact form — undoing
    /// the fixed-decimal-places padding a scrub session keeps live (see `formattedDragValue`) now
    /// that it's ending. Hex is skipped naturally: it doesn't parse as a `Double`.
    private func finalizeValues(layout: DecomposedColor) {
        for (i, component) in layout.components.enumerated() where i < values.count {
            guard let n = Double(values[i].trimmingCharacters(in: .whitespaces)) else { continue }
            let clamped = component.range.map { min(max(n, $0.lowerBound), $0.upperBound) } ?? n
            values[i] = ColorComponentField.formattedDragValue(clamped, kind: component.kind)
        }
    }

    private func commitEditing() {
        // Called on Return: drop focus, which routes through finishEditing().
        focusedIndex = nil
    }

    private func finishEditing() {
        let layout = decomposed
        let allValid = zip(layout.components, values).allSatisfy { $0.isValid($1) }
        if allValid, let color = format.recompose(values, style: style, in: colorSpace) {
            eyedropper.set(color)
            lastPreviewedColor = eyedropper.color
            NotificationCenter.default.post(name: .colorPicked, object: nil)
            // `recompose` already clamps an out-of-range number rather than rejecting it (see
            // `ColorComponent.isValid`); snap the displayed text to match what was actually
            // used, rather than leaving e.g. a typed "400" showing next to a hue that's
            // actually 360.
            finalizeValues(layout: layout)
            // Don't otherwise resync `values` from the just-committed colour: some formats are
            // lossy at their extremes (e.g. HSB hue/saturation are undefined at brightness 0),
            // so decomposing straight back can silently discard what was just typed — e.g.
            // typing hsb(0, 50%, 0%) round-trips through black and reports back 0% saturation.
            // `values` already holds exactly what was committed, which is the more faithful
            // thing to show.
            endSession(resync: false)
        } else if let preEditColor {
            eyedropper.set(preEditColor)
            lastPreviewedColor = eyedropper.color
            endSession(resync: true)
        } else {
            endSession(resync: true)
        }
    }

    private func revertEditing() {
        if let preEditColor {
            lastPreviewedColor = preEditColor
            eyedropper.set(preEditColor)
        }
        focusedIndex = nil
        endSession(resync: true)
    }

    /// An external eyedropper pick landed while a field was focused — abort the edit so the
    /// pick wins, rather than letting a later blur silently overwrite it with typed values.
    private func abortEditingForExternalPick() {
        focusedIndex = nil
        endSession(resync: true)
    }

    private func endSession(resync: Bool) {
        isEditing = false
        isScrubbing = false
        rowScrubPreview = nil
        frozenSize = nil
        isInvalid = false
        preEditColor = nil
        sessionOwner = nil
        rowScrubPreview = nil
        // Only clear the own-write marker when we're about to resync anyway. A `resync: false`
        // commit (see `finishEditing`'s success path) deliberately keeps `values` as typed rather
        // than the freshly (and possibly lossily) decomposed colour — clearing this unconditionally
        // made the very next `onChange(of: eyedropper.color)` pass see `newValue != nil` and
        // resync anyway, undoing that on the next render and silently discarding what was just
        // committed (e.g. hue snapping back to 0 once brightness/saturation round-trip through it).
        if resync {
            lastPreviewedColor = nil
            syncValuesFromColor(decomposed)
        }
    }
}

/// A single focusable numeric/hex field styled to the swatch's UI colour, with the four design
/// states: default (bare), hover (filled), focus (outlined), invalid (dashed outline).
///
/// Backed by a custom `NSTextField` (`ScrubTextField`, in `ScrubTextField.swift`) rather than a plain SwiftUI
/// `TextField`. Three attempts to bolt click-drag-to-scrub onto a native `TextField` via
/// SwiftUI `DragGesture`/local event monitors all lost the race against AppKit's own
/// click-to-focus — a raw mouseDown on a real `TextField` always focuses/selects it immediately,
/// before any gesture recognizer gets a chance to see the drag. Owning `mouseDown` directly is
/// the only way to decide click-vs-drag *before* anything focuses.
struct ColorComponentField: View {
    @Binding var text: String
    let component: ColorComponent
    let index: Int
    let uiColor: NSColor
    let fontSize: CGFloat
    @Binding var focusedIndex: Int?
    let onSubmit: () -> Void
    let onCancel: () -> Void
    /// Fired when a drag-to-scrub gesture starts/ends, so the parent can wrap it in the same
    /// live-preview/commit session used for typed edits (one history entry per drag, not per pixel).
    let onDragBegin: () -> Void
    let onDragEnd: () -> Void
    /// Fired with the raw live value on every drag/scroll step, so the parent can preview the
    /// eyedropper colour without touching `text` (which stays frozen for the gesture — see
    /// `rowScrubPreview`).
    let onLiveValue: (Double, Int) -> Double

    @State private var isHovering = false
    /// Non-nil while a two-finger scroll-to-scrub gesture owns this field; holds the value at
    /// scroll start. `scrollAccumulated` tracks total vertical scroll since then.
    @State private var scrollOrigin: Double?
    @State private var scrollAccumulated: CGFloat = 0
    /// The last value computed during an active scroll — nil once no scroll is in progress.
    /// Committed to `text` in `handleScrollEnded`, since the field's own text stays frozen
    /// (see `EditableColorValue.rowScrubPreview`) for the live-updating part of the gesture.
    @State private var scrollLastValue: Double?
    /// Decimal places to hold this scroll session's live display at — captured once at scroll
    /// start (see `stableDecimalPlaces(for:)`) and held fixed for the session, same reasoning as
    /// `ScrubTextField.dragDecimalPlaces`.
    @State private var scrollDecimalPlaces = 2
    /// Non-nil while a click-drag or scroll scrub is live: the value the field's own text stays
    /// completely frozen against (no re-shrink/re-wrap risk, since nothing about the row's text
    /// changes for the rest of the session) is instead shown here, in a floating pill above the
    /// field — a value's own rendered width still isn't perfectly stable digit-for-digit even at
    /// a fixed decimal-place count (e.g. "0.0000" vs "0.1111" in a proportional font), so a
    /// preview that doesn't participate in `FlowLayout`'s sizing at all is the only way to fully
    /// rule out wrap flicker while scrubbing.
    /// Bumped on every focus event (begin or end) this field reports; see the deferred-blur
    /// comment at its use in `onFocusChange` below.
    @State private var focusVersion = 0

    private var isFocused: Bool { focusedIndex == index }
    private var isInvalid: Bool { isFocused && !component.isValid(text) }
    /// Hex is a single opaque string with no natural min/max to scrub between.
    private var isDraggable: Bool { component.kind != .hex }

    var body: some View {
        ScrubbableColorField(
            text: $text,
            fontSize: fontSize,
            textColor: uiColor,
            isDraggable: isDraggable,
            range: component.range,
            kind: component.kind,
            isFocused: isFocused,
            onFocusChange: { focused in
                // AppKit doesn't always report a clean single "begin": both a direct
                // field-to-field focus move (old field resigns before the new one becomes first
                // responder) *and*, it turns out, a field gaining focus from nothing at all
                // (its own internal resign/become choreography when a click lands on it) can
                // report a spurious "end" immediately before — or, in the from-nothing case,
                // interleaved with — the real "begin". Reacting to an "end" synchronously would
                // tear the whole edit session down for a frame (dropping the outline, ending
                // editing) only to immediately restart it — or, worse, incorrectly cancel a
                // "begin" for the very same field that arrives a moment later. Defer the "end"
                // one runloop turn and only apply it if nothing else has touched focus since:
                // `focusVersion` is bumped on every focus event, so a later event (for this
                // field or another) invalidates a stale deferred "end".
                focusVersion += 1
                if focused {
                    focusedIndex = index
                } else {
                    let expectedVersion = focusVersion
                    DispatchQueue.main.async {
                        guard focusVersion == expectedVersion, focusedIndex == index else { return }
                        focusedIndex = nil
                    }
                }
            },
            onSubmit: onSubmit,
            onCancel: onCancel,
            onDragBegin: onDragBegin,
            onDragEnd: onDragEnd,
            onDragCancel: onCancel,
            onLiveValue: onLiveValue,
            onStep: isDraggable ? stepValue : nil
        )
        .fixedSize()
        .padding(.horizontal, 1)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(uiColor).opacity(isHovering && !isFocused ? 0.18 : 0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    Color(uiColor).opacity(isFocused ? 0.9 : 0),
                    style: StrokeStyle(lineWidth: 1, dash: isInvalid ? [2, 2] : [])
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            guard !isFocused else { return }
            // Only show the scrub cursor where scrubbing is actually possible; hex has no
            // natural min/max to scrub between, so it keeps the ordinary text cursor.
            if hovering { (isDraggable ? NSCursor.resizeLeftRight : NSCursor.iBeam).set() } else { NSCursor.arrow.set() }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .animation(.easeInOut(duration: 0.12), value: isFocused)
        .background(
            Group {
                if isDraggable {
                    ScrollValueAdapter(
                        isEnabled: !isFocused,
                        onScroll: handleScrollDelta,
                        onScrollEnd: handleScrollEnded
                    )
                }
            }
            .allowsHitTesting(false)
        )
    }

    /// Up/Down arrow keys nudge the focused field by one `dragUnitsPerPixel` step (a tenth of
    /// that with Option), same as a single step of click-drag or scroll scrubbing — applied
    /// straight to the live-preview binding since the field is already mid-edit (it has to be
    /// focused to receive the key at all).
    private func stepValue(_ direction: CGFloat) {
        let current = Double(text.trimmingCharacters(in: .whitespaces)) ?? 0
        let fine = NSEvent.modifierFlags.contains(.option)
        let unitsPerStep = dragUnitsPerPixel(for: component.range)
        var newValue = current + Double(direction) * unitsPerStep * (fine ? 0.1 : 1.0)
        if let range = component.range {
            newValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
        let places = Self.stableDecimalPlaces(for: text)
        text = Self.formattedDragValue(newValue, kind: component.kind, stableDecimalPlaces: places)
    }

    /// Two-finger trackpad scroll nudges the value the same way click-drag does: accumulated
    /// vertical scroll maps to `dragUnitsPerPixel` units per point (a tenth of that while
    /// holding Option), clamped to range.
    private func handleScrollDelta(_ deltaY: CGFloat) {
        guard isDraggable else { return }
        if scrollOrigin == nil {
            scrollOrigin = Double(text.trimmingCharacters(in: .whitespaces)) ?? 0
            scrollAccumulated = 0
            scrollDecimalPlaces = min(
                ScrubTextField.precisionRange.upperBound,
                max(
                    Self.naturalDecimalPlaces(forRange: component.range),
                    Self.stableDecimalPlaces(for: text)
                )
            )
            onDragBegin()
        }
        guard let origin = scrollOrigin else { return }
        // Inverted: scrolling up (negative deltaY) increases the value, matching the direction
        // users expect when nudging a number via a scroll gesture.
        scrollAccumulated -= deltaY
        let fine = NSEvent.modifierFlags.contains(.option)
        let unitsPerStep = dragUnitsPerPixel(for: component.range)
        var newValue = origin + Double(scrollAccumulated) * unitsPerStep * (fine ? 0.1 : 1.0)
        if let range = component.range {
            newValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
        let achieved = onLiveValue(newValue, scrollDecimalPlaces)
        scrollLastValue = achieved
    }

    private func handleScrollEnded() {
        guard scrollOrigin != nil else { return }
        if let scrollLastValue {
            text = Self.formattedDragValue(scrollLastValue, kind: component.kind, stableDecimalPlaces: scrollDecimalPlaces)
        }
        scrollOrigin = nil
        scrollAccumulated = 0
        scrollLastValue = nil
        onDragEnd()
    }

    /// A non-nil `stableDecimalPlaces` rounds every decimal to that many fixed places instead of
    /// the usual zero-stripped up-to-4 (e.g. "0.22" rather than "0.2200" or "0.2263") — pass it
    /// while a scrub session is live: the zero-stripped form's length changes with the value,
    /// which shifts `FlowLayout`'s wrap points on essentially every frame of the drag. Fixed
    /// places holds that length steady; see `stableDecimalPlaces(for:)` for how many. The caller
    /// restrips to the normal compact form once the session ends (`finalizeValues`).
    static func formattedDragValue(_ value: Double, kind: ComponentKind, stableDecimalPlaces: Int? = nil) -> String {
        switch kind {
        case .hex:
            return ""
        case .integer:
            return String(Int(value.rounded()))
        case .decimal:
            guard let places = stableDecimalPlaces else {
                return CGFloat(value).strippedDecimalString(maxDecimalPlaces: 4)
            }
            return String(format: "%.\(places)f", value)
        }
    }

    /// Decimal places at which this component's per-pixel drag step is actually visible: the
    /// step is range-scaled (`dragUnitsPerPixel`), so a fixed 2 places leaves a fine-ranged
    /// component like OKLCH chroma advancing its last digit only every ~4px — which reads as the
    /// number being stuck while the colour plainly changes. Derived from the step so the last
    /// digit always moves about once per pixel.
    static func naturalDecimalPlaces(forRange range: ClosedRange<Double>?) -> Int {
        let step = dragUnitsPerPixel(for: range)
        guard step > 0 else { return 2 }
        return max(0, Int(ceil(-log10(step))))
    }

    /// Decimal places for a scrub session's live display: 2 by default — finer than that isn't a
    /// meaningful step to scrub by (0.0001 of a 0...1 range is imperceptible per pixel) — unless
    /// the value already displays with more precision than that, in which case keep it. Otherwise
    /// starting a scrub would itself immediately truncate the value and reflow the row, before
    /// any actual dragging has happened.
    static func stableDecimalPlaces(for text: String) -> Int {
        guard let dotIndex = text.firstIndex(of: ".") else { return 2 }
        let decimals = text.distance(from: text.index(after: dotIndex), to: text.endIndex)
        return max(2, min(4, decimals))
    }
}
