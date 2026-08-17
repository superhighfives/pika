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
                        onLiveValue: { value in previewLiveScrub(index: index, layout: layout, value: value) }
                    )
                    if index < layout.separators.count {
                        affix(layout.separators[index], size: size)
                    } else {
                        affix(layout.trailing, size: size)
                    }
                }
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
        } else if isEditing {
            // Focus left every field (blur / tab-out) — commit if valid, otherwise revert.
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
        finishEditing()
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
        // Sized to the *widest possible* value for this format, not the current one: keeping
        // `frozenSize` in step with the live value (as it started out) only froze the font size,
        // not the wrap decision — a component can still change digit count as it's scrubbed
        // (e.g. "0.25" → "0.3"), which shifts where FlowLayout breaks the line even at a fixed
        // font size. Sizing conservatively for the worst case up front means no value this
        // format can ever produce needs more room than what's already budgeted, so the number of
        // lines genuinely can't change for the rest of the session, however the digits move.
        frozenSize = fontSize(for: worstCaseJoined(layout))
        preEditColor = eyedropper.color
        values = layout.values
        valuesKey = FormatStyleKey(format: format, style: style, colorSpace: colorSpace)
    }

    /// The longest string this format's layout could ever produce: same scaffolding (leading/
    /// separators/trailing) as `layout.joined()`, but each component replaced with its own
    /// worst-case placeholder — see `worstCaseComponentString`.
    private func worstCaseJoined(_ layout: DecomposedColor) -> String {
        var result = layout.leading
        for (index, component) in layout.components.enumerated() {
            result += worstCaseComponentString(component)
            if index < layout.separators.count { result += layout.separators[index] }
        }
        return result + layout.trailing
    }

    /// The widest value a component could ever display. Integers use the range's most digits;
    /// decimals use the range's most integer-part digits plus 4 decimal places (the original
    /// stripped format's max — still the true worst case even though scrubbing now defaults to
    /// coarser 2-place rounding, since finer starting precision is preserved up to 4). A leading
    /// "-" is budgeted for any component whose range allows (or has no range, e.g. Lab a/b) a
    /// negative value. Unranged decimals (Lab a/b) have no clamp and are genuinely unbounded, so
    /// there's no true worst case to size to; 3 int digits is a practical bound that covers real
    /// sRGB-gamut a*/b* extremes (b* reaches roughly -107) without reserving excessive width.
    /// Hex is already fixed-length, so it's left as-is.
    private func worstCaseComponentString(_ component: ColorComponent) -> String {
        let sign = (component.range?.lowerBound ?? -1) < 0 ? "-" : ""
        switch component.kind {
        case .hex:
            return component.value
        case .integer:
            let digits = component.range.map { String(abs(Int($0.upperBound.rounded()))).count } ?? 3
            return sign + String(repeating: "9", count: max(digits, 1))
        case .decimal:
            let intDigits = component.range.map {
                max(String(abs(Int($0.upperBound))).count, String(abs(Int($0.lowerBound))).count)
            } ?? 3
            return sign + String(repeating: "9", count: max(intDigits, 1)) + "." + String(repeating: "9", count: 4)
        }
    }

    /// Recompose the working values and preview them live; flag invalid input for the pill.
    private func previewIfValid(layout: DecomposedColor) {
        let allValid = zip(layout.components, values).allSatisfy { $0.isValid($1) }
        isInvalid = !allValid
        guard allValid, let color = format.recompose(values, style: style, in: colorSpace) else { return }
        eyedropper.set(color)
        lastPreviewedColor = eyedropper.color
    }

    /// Live-previews the eyedropper colour for a single component's in-progress drag/scroll
    /// value, mirroring `previewIfValid`'s recompose-and-set against a substituted value —
    /// without touching `values`/`text`, which stay frozen for the whole gesture so `FlowLayout`
    /// never reflows mid-scrub (see `scrubPreviewText`).
    private func previewLiveScrub(index: Int, layout: DecomposedColor, value: Double) {
        guard index < layout.components.count else { return }
        let currentKey = FormatStyleKey(format: format, style: style, colorSpace: colorSpace)
        var liveValues = (valuesKey == currentKey && values.count == layout.components.count) ? values : layout.values
        guard index < liveValues.count else { return }
        liveValues[index] = ColorComponentField.formattedDragValue(value, kind: layout.components[index].kind)
        guard let color = format.recompose(liveValues, style: style, in: colorSpace) else { return }
        eyedropper.set(color)
        lastPreviewedColor = eyedropper.color
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
        frozenSize = nil
        isInvalid = false
        preEditColor = nil
        sessionOwner = nil
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
    /// `scrubPreviewText`).
    let onLiveValue: (Double) -> Void

    @State private var isHovering = false
    /// Non-nil while a two-finger scroll-to-scrub gesture owns this field; holds the value at
    /// scroll start. `scrollAccumulated` tracks total vertical scroll since then.
    @State private var scrollOrigin: Double?
    @State private var scrollAccumulated: CGFloat = 0
    /// The last value computed during an active scroll — nil once no scroll is in progress.
    /// Committed to `text` in `handleScrollEnded`, since the field's own text stays frozen
    /// (see `scrubPreviewText`) for the live-updating part of the gesture.
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
    @State private var scrubPreviewText: String?
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
            onScrubPreview: { scrubPreviewText = $0 },
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
        // Purely decorative: an `.overlay` doesn't feed back into this view's own reported size,
        // so the pill can appear, change text, and disappear without ever perturbing `FlowLayout`.
        .overlay(alignment: .top) {
            if let scrubPreviewText {
                Text(scrubPreviewText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.85)))
                    .fixedSize()
                    .offset(y: -26)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.1), value: scrubPreviewText)
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
            scrollDecimalPlaces = Self.stableDecimalPlaces(for: text)
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
        scrollLastValue = newValue
        scrubPreviewText = Self.formattedDragValue(newValue, kind: component.kind, stableDecimalPlaces: scrollDecimalPlaces)
        onLiveValue(newValue)
    }

    private func handleScrollEnded() {
        guard scrollOrigin != nil else { return }
        if let scrollLastValue {
            text = Self.formattedDragValue(scrollLastValue, kind: component.kind, stableDecimalPlaces: scrollDecimalPlaces)
        }
        scrollOrigin = nil
        scrollAccumulated = 0
        scrollLastValue = nil
        scrubPreviewText = nil
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
