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

private struct EditableWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
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
    /// Raised while the focused field holds unparseable input, so the parent can show the pill.
    @Binding var isInvalid: Bool

    private let baseSize: CGFloat = 18
    private let minSize: CGFloat = 11

    /// Identifies which (format, style) a cached `values` array was decomposed for, so a
    /// format/style switch is detected even when the component count doesn't change (every
    /// non-hex format always has exactly 3 components).
    private struct FormatStyleKey: Equatable {
        let format: ColorFormat
        let style: CopyFormat
    }

    @State private var width: CGFloat = 0
    /// Working component strings. Kept in sync with the colour when idle; owned by the user
    /// while a field is focused.
    @State private var values: [String] = []
    @State private var valuesKey: FormatStyleKey?
    @State private var isEditing = false
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

    private var decomposed: DecomposedColor {
        format.decompose(eyedropper.color, style: style, in: colorSpace)
    }

    private var uiColor: NSColor { eyedropper.color.getUIColor() }

    // Deterministic font size from the full string width vs column width — same approach as the
    // read-only AdaptiveValueText, but single-line (a wrapping row of fields reads poorly).
    private func fontSize(for text: String) -> CGFloat {
        guard width > 4 else { return baseSize }
        let full = (text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: baseSize)]).width
        guard full > 0 else { return baseSize }
        let scale = min(1, width / full)
        return max(minSize, baseSize * scale)
    }

    var body: some View {
        let layout = decomposed
        let size = fontSize(for: layout.joined())

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            affix(layout.leading, size: size)
            ForEach(Array(layout.components.enumerated()), id: \.offset) { index, component in
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
                    onDragEnd: finishEditing
                )
                if index < layout.separators.count {
                    affix(layout.separators[index], size: size)
                }
            }
            affix(layout.trailing, size: size)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: EditableWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(EditableWidthKey.self) { width = $0 }
        .onAppear { syncValuesFromColor(layout) }
        .onChange(of: focusedIndex) { newValue in handleFocusChange(to: newValue, layout: layout) }
        .onChange(of: eyedropper.color) { newValue in
            if isEditing {
                // A change we didn't push ourselves is an external pick landing mid-edit —
                // abort the session so the external colour wins, matching pre-edit behaviour.
                if newValue != lastPreviewedColor { abortEditingForExternalPick() }
            } else {
                syncValuesFromColor(decomposed)
            }
        }
        .onChange(of: format) { _ in handleFormatOrStyleChange() }
        .onChange(of: style) { _ in handleFormatOrStyleChange() }
    }

    private func affix(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(Color(uiColor).opacity(0.5))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Values ↔ colour

    private func syncValuesFromColor(_ layout: DecomposedColor) {
        values = layout.values
        valuesKey = FormatStyleKey(format: format, style: style)
    }

    private func binding(for index: Int, layout: DecomposedColor) -> Binding<String> {
        let currentKey = FormatStyleKey(format: format, style: style)
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

    /// A format or copy-style switch changes how the same colour is *displayed*, not the colour
    /// itself. Mid-edit, the typed values are in the old format's units and can't be reinterpreted
    /// safely, so abort the session rather than risk a bogus commit; otherwise just resync.
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
        if isEditing {
            focusedIndex = index
            return
        }
        startSession(layout: layout)
    }

    private func handleFocusChange(to newValue: Int?, layout: DecomposedColor) {
        if newValue != nil {
            // Entering (or moving between) fields — start a session on the first focus.
            if !isEditing {
                startSession(layout: layout)
            }
        } else if isEditing {
            // Focus left every field (blur / tab-out) — commit if valid, otherwise revert.
            finishEditing()
        }
    }

    /// Snapshot the colour and working values at the start of an edit or drag session, so
    /// `finishEditing`/`abortEditingForExternalPick` have a consistent point to commit or revert to.
    private func startSession(layout: DecomposedColor) {
        isEditing = true
        preEditColor = eyedropper.color
        values = layout.values
        valuesKey = FormatStyleKey(format: format, style: style)
    }

    /// Recompose the working values and preview them live; flag invalid input for the pill.
    private func previewIfValid(layout: DecomposedColor) {
        let allValid = zip(layout.components, values).allSatisfy { $0.isValid($1) }
        isInvalid = !allValid
        guard allValid, let color = format.recompose(values, style: style, in: colorSpace) else { return }
        eyedropper.set(color)
        lastPreviewedColor = eyedropper.color
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
        } else if let preEditColor {
            eyedropper.set(preEditColor)
            lastPreviewedColor = eyedropper.color
        }
        endSession()
    }

    private func revertEditing() {
        if let preEditColor {
            lastPreviewedColor = preEditColor
            eyedropper.set(preEditColor)
        }
        focusedIndex = nil
        endSession()
    }

    /// An external eyedropper pick landed while a field was focused — abort the edit so the
    /// pick wins, rather than letting a later blur silently overwrite it with typed values.
    private func abortEditingForExternalPick() {
        focusedIndex = nil
        endSession()
    }

    private func endSession() {
        isEditing = false
        isInvalid = false
        preEditColor = nil
        lastPreviewedColor = nil
        syncValuesFromColor(decomposed)
    }
}

/// A single focusable numeric/hex field styled to the swatch's UI colour, with the four design
/// states: default (bare), hover (filled), focus (outlined), invalid (dashed outline).
///
/// Backed by a custom `NSTextField` (`ScrubTextField`, below) rather than a plain SwiftUI
/// `TextField`. Three attempts to bolt click-drag-to-scrub onto a native `TextField` via
/// SwiftUI `DragGesture`/local event monitors all lost the race against AppKit's own
/// click-to-focus — a raw mouseDown on a real `TextField` always focuses/selects it immediately,
/// before any gesture recognizer gets a chance to see the drag. Owning `mouseDown` directly is
/// the only way to decide click-vs-drag *before* anything focuses.
private struct ColorComponentField: View {
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

    @State private var isHovering = false
    /// Non-nil while a two-finger scroll-to-scrub gesture owns this field; holds the value at
    /// scroll start. `scrollAccumulated` tracks total vertical scroll since then.
    @State private var scrollOrigin: Double?
    @State private var scrollAccumulated: CGFloat = 0

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
            onFocusChange: { focused in focusedIndex = focused ? index : (focusedIndex == index ? nil : focusedIndex) },
            onSubmit: onSubmit,
            onCancel: onCancel,
            onDragBegin: onDragBegin,
            onDragEnd: onDragEnd
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

    /// Two-finger trackpad scroll nudges the value the same way click-drag does: accumulated
    /// vertical scroll maps 1 unit per point (0.1 while holding Option), clamped to range.
    private func handleScrollDelta(_ deltaY: CGFloat) {
        guard isDraggable else { return }
        if scrollOrigin == nil {
            scrollOrigin = Double(text.trimmingCharacters(in: .whitespaces)) ?? 0
            scrollAccumulated = 0
            onDragBegin()
        }
        guard let origin = scrollOrigin else { return }
        // Inverted: scrolling up (negative deltaY) increases the value, matching the direction
        // users expect when nudging a number via a scroll gesture.
        scrollAccumulated -= deltaY
        let fine = NSEvent.modifierFlags.contains(.option)
        var newValue = origin + Double(scrollAccumulated) * (fine ? 0.1 : 1.0)
        if let range = component.range {
            newValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
        text = Self.formattedDragValue(newValue, kind: component.kind)
    }

    private func handleScrollEnded() {
        guard scrollOrigin != nil else { return }
        scrollOrigin = nil
        scrollAccumulated = 0
        onDragEnd()
    }

    fileprivate static func formattedDragValue(_ value: Double, kind: ComponentKind) -> String {
        switch kind {
        case .hex:
            return ""
        case .integer:
            return String(Int(value.rounded()))
        case .decimal:
            return CGFloat(value).strippedDecimalString(maxDecimalPlaces: 4)
        }
    }
}

/// Captures two-finger trackpad scroll events landing within the wrapped view's bounds and
/// reports vertical delta/end, mirroring `HorizontalScrollWheelAdapter`'s local-monitor approach
/// so a scrub field can be nudged the same way click-drag nudges it.
private struct ScrollValueAdapter: NSViewRepresentable {
    let isEnabled: Bool
    let onScroll: (CGFloat) -> Void
    let onScrollEnd: () -> Void

    func makeNSView(context _: Context) -> ScrollCaptureView {
        let view = ScrollCaptureView()
        view.isEnabled = isEnabled
        view.onScroll = onScroll
        view.onScrollEnd = onScrollEnd
        return view
    }

    func updateNSView(_ view: ScrollCaptureView, context _: Context) {
        view.isEnabled = isEnabled
        view.onScroll = onScroll
        view.onScrollEnd = onScrollEnd
    }

    final class ScrollCaptureView: NSView {
        var isEnabled = true
        var onScroll: ((CGFloat) -> Void)?
        var onScrollEnd: (() -> Void)?
        private var monitor: Any?
        private var isScrolling = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil, monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                    self?.handle(event) ?? event
                }
            } else if window == nil, let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard isEnabled, event.window === window, let window else { return event }

            // Once we own an in-progress scroll, keep tracking it no matter where the cursor
            // goes: trackpad momentum keeps delivering events (often with a final `.ended`
            // phase) after the user's fingers leave the trackpad, and by then the cursor has
            // frequently drifted off this field. Gating termination on `bounds.contains` meant
            // that final event was silently dropped, `onScrollEnd` never fired, and the parent's
            // edit session leaked open — so the *next* field touched would find a stale
            // "already editing" session and force-focus itself.
            if isScrolling {
                if event.phase == .ended || event.phase == .cancelled || event.momentumPhase == .ended {
                    isScrolling = false
                    onScrollEnd?()
                    return event
                }
                guard event.hasPreciseScrollingDeltas else { return event }
                let deltaY = event.scrollingDeltaY
                guard deltaY != 0 else { return event }
                onScroll?(deltaY)
                return nil
            }

            let pointInSelf = convert(event.locationInWindow, from: nil)
            guard bounds.contains(pointInSelf) else { return event }

            // Only intervene for trackpad/Magic Mouse gesture scrolling, which carries
            // phase/precise deltas; classic scroll wheels should keep their default behaviour.
            guard event.hasPreciseScrollingDeltas else { return event }
            guard event.phase != .ended, event.phase != .cancelled, event.momentumPhase != .ended else { return event }

            let deltaY = event.scrollingDeltaY
            guard deltaY != 0 else { return event }
            isScrolling = true
            onScroll?(deltaY)
            return nil
        }
    }
}

/// Wraps `ScrubTextField` (below) for SwiftUI. Owns focus explicitly via `isFocused`/
/// `onFocusChange` rather than `@FocusState`/`.focused()` (which don't bridge to a custom
/// `NSViewRepresentable`), synced through the field's own `NSTextFieldDelegate` callbacks so it
/// stays correct however focus changes — click, Tab, or a programmatic request.
private struct ScrubbableColorField: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let textColor: NSColor
    let isDraggable: Bool
    let range: ClosedRange<Double>?
    let kind: ComponentKind
    let isFocused: Bool
    let onFocusChange: (Bool) -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void
    /// Fired when a click-drag-to-scrub gesture starts/ends, so the parent can wrap it in the
    /// same live-preview/commit session used for typed edits.
    let onDragBegin: () -> Void
    let onDragEnd: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onCancel: onCancel, onFocusChange: onFocusChange)
    }

    func makeNSView(context: Context) -> ScrubTextField {
        let field = ScrubTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .center
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.delegate = context.coordinator
        field.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        field.stringValue = text
        return field
    }

    func updateNSView(_ nsView: ScrubTextField, context: Context) {
        context.coordinator.text = $text
        if nsView.font?.pointSize != fontSize {
            nsView.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
            nsView.invalidateIntrinsicContentSize()
        }
        nsView.textColor = textColor
        nsView.isDraggable = isDraggable
        nsView.range = range
        nsView.kind = kind
        nsView.onDragBegin = onDragBegin
        nsView.onDragChanged = { [weak nsView] newValue in
            nsView?.stringValue = ColorComponentField.formattedDragValue(newValue, kind: kind)
            text = nsView?.stringValue ?? text
        }
        nsView.onDragEnd = onDragEnd

        if nsView.stringValue != text {
            nsView.stringValue = text
            nsView.invalidateIntrinsicContentSize()
            // A programmatic change (drag/scroll, or an external colour landing mid-edit) while
            // this field is still first responder — keep the caret collapsed at the end rather
            // than whatever AppKit does by default when `stringValue` changes underneath it.
            if let editor = nsView.currentEditor() as? NSTextView {
                let length = (text as NSString).length
                editor.selectedRange = NSRange(location: length, length: 0)
            }
        }

        let editorIsActive = nsView.currentEditor() != nil && nsView.window?.firstResponder === nsView.currentEditor()
        if isFocused, !editorIsActive {
            nsView.window?.makeFirstResponder(nsView)
        } else if !isFocused, editorIsActive {
            nsView.window?.makeFirstResponder(nil)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        let onSubmit: () -> Void
        let onCancel: () -> Void
        let onFocusChange: (Bool) -> Void

        init(text: Binding<String>, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void, onFocusChange: @escaping (Bool) -> Void) {
            self.text = text
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self.onFocusChange = onFocusChange
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }

        func controlTextDidBeginEditing(_: Notification) { onFocusChange(true) }
        func controlTextDidEndEditing(_: Notification) { onFocusChange(false) }

        func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onCancel()
                return true
            }
            return false
        }
    }
}

/// A plain `NSTextField` subclass that owns its own `mouseDown`, so click-vs-drag is resolved
/// *before* anything can focus — no second view or event monitor racing the field's native click
/// handling. A resolved drag never touches first-responder status at all, so the field just
/// displays a changing string like a label while scrubbing (no editor, no selection, no caret).
/// A resolved click focuses normally; `becomeFirstResponder` then deterministically collapses
/// AppKit's default select-all in the same call stack, rather than reacting to it after the fact.
private final class ScrubTextField: NSTextField {
    var isDraggable = false {
        didSet { window?.invalidateCursorRects(for: self) }
    }

    var range: ClosedRange<Double>?
    var kind: ComponentKind = .integer
    var onDragBegin: (() -> Void)?
    var onDragChanged: ((Double) -> Void)?
    var onDragEnd: (() -> Void)?

    private var dragOrigin: Double?

    // The default NSTextFieldCell intrinsic size proved unreliable once `.fixedSize()` queried
    // it eagerly (fields collapsed to ~0pt wide) — compute it directly from the string and font
    // instead of trusting the cell's own layout pass.
    override var intrinsicContentSize: NSSize {
        let currentFont = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let size = (stringValue as NSString).size(withAttributes: [.font: currentFont])
        return NSSize(width: ceil(size.width) + 2, height: ceil(size.height))
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            if let editor = currentEditor() {
                let length = (editor.string as NSString).length
                editor.selectedRange = NSRange(location: length, length: 0)
            }
            window?.invalidateCursorRects(for: self)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { window?.invalidateCursorRects(for: self) }
        return result
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.invalidateCursorRects(for: self)
    }

    // NSTextField's own `resetCursorRects()` covers `bounds` with an I-beam cursor rect, which
    // wins over the SwiftUI `.onHover`-driven `NSCursor.set()` the moment the mouse enters this
    // AppKit view — that's why the resize cursor from the parent's hover handling was reverting
    // to `|` over the text itself. Claim the rect ourselves while draggable and not being edited.
    override func resetCursorRects() {
        guard isDraggable, currentEditor() == nil else {
            super.resetCursorRects()
            return
        }
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        guard isDraggable else {
            super.mouseDown(with: event)
            return
        }

        let startPoint = event.locationInWindow
        var didBeginDrag = false
        let threshold: CGFloat = 2

        // Every exit path below must resolve exactly one of "focus" or a paired
        // onDragBegin/onDragEnd — an orphaned "began but never ended" session would leave the
        // parent's edit session stuck open, making the next interaction silently join it instead
        // of starting fresh.
        while true {
            guard let next = NSApp.nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: true
            ) else {
                if didBeginDrag { finishDrag() }
                return
            }

            switch next.type {
            case .leftMouseDragged:
                let translationX = next.locationInWindow.x - startPoint.x
                if !didBeginDrag {
                    guard abs(translationX) >= threshold else { continue }
                    didBeginDrag = true
                    beginDrag()
                }
                updateDrag(translationX: translationX)
            case .leftMouseUp:
                if didBeginDrag {
                    finishDrag()
                } else {
                    // A genuine click: focus normally, exactly like a plain click on any
                    // ordinary text field would.
                    window?.makeFirstResponder(self)
                }
                return
            default:
                if didBeginDrag { finishDrag() }
                return
            }
        }
    }

    private func beginDrag() {
        dragOrigin = Double(stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        NSCursor.resizeLeftRight.set()
        onDragBegin?()
    }

    private func updateDrag(translationX: CGFloat) {
        guard let origin = dragOrigin else { return }
        let fine = NSEvent.modifierFlags.contains(.option)
        var newValue = origin + Double(translationX) * (fine ? 0.1 : 1.0)
        if let range {
            newValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
        onDragChanged?(newValue)
    }

    private func finishDrag() {
        dragOrigin = nil
        NSCursor.arrow.set()
        onDragEnd?()
    }
}
