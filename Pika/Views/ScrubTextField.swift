import AppKit
import SwiftUI

/// Captures two-finger trackpad scroll events landing within the wrapped view's bounds and
/// reports vertical delta/end, mirroring `HorizontalScrollWheelAdapter`'s local-monitor approach
/// so a scrub field can be nudged the same way click-drag nudges it.
struct ScrollValueAdapter: NSViewRepresentable {
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
struct ScrubbableColorField: NSViewRepresentable {
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
    /// Escape pressed mid-drag — abandon the scrub and put the colour back how it was.
    let onDragCancel: () -> Void
    /// Fired with the raw live value on every drag step, so the parent can preview the eyedropper
    /// colour without touching `text`, which stays frozen for the whole gesture.
    let onLiveValue: (Double) -> Double
    /// Fired with +1/-1 for Up/Down arrow keys, `nil` for non-draggable (hex) fields.
    let onStep: ((CGFloat) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onCancel: onCancel, onStep: onStep)
    }

    func makeNSView(context: Context) -> ScrubTextField {
        let field = ScrubTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        // Left, not center: the field's frame is already sized to fit its text almost exactly
        // (`intrinsicContentSize`, below), so centring only has ~2pt of slack to distribute. The
        // static cell measures that slack with `NSString.size(withAttributes:)`; the live field
        // editor lays the same string out via TextKit, which can measure it a device pixel
        // narrower/wider — enough to visibly shift the centred text the moment editing begins.
        // Left alignment anchors the text to the same edge under both renderers, so it doesn't move.
        field.alignment = .left
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.delegate = context.coordinator
        field.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        field.stringValue = text
        return field
    }

    func updateNSView(_ nsView: ScrubTextField, context: Context) {
        context.coordinator.text = $text
        // Driven off `becomeFirstResponder`/`resignFirstResponder` directly rather than the
        // `NSTextFieldDelegate` controlTextDidBeginEditing/EndEditing notifications: a click that
        // lands on a not-yet-focused field goes through AppKit's own private pre-focus path
        // (`NSWindow._handleMouseDownEvent:` → `NSTextFieldCell _selectOrEdit:…`) *before* this
        // view's `mouseDown` override ever runs, and that path never posts the notifications the
        // delegate relies on — so `focusedIndex` silently never got set, and the focus outline
        // never appeared. The responder overrides fire reliably however focus changes.
        nsView.onFocusChange = onFocusChange
        context.coordinator.onStep = onStep
        if nsView.font?.pointSize != fontSize {
            nsView.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
            nsView.invalidateIntrinsicContentSize()
        }
        nsView.textColor = textColor
        nsView.isDraggable = isDraggable
        nsView.range = range
        nsView.kind = kind
        nsView.onDragBegin = onDragBegin
        nsView.onDragCancel = { [weak nsView] in
            nsView?.lastAchievedValue = nil
            onDragCancel()
        }
        // The field's own `stringValue` is deliberately never touched here — it stays frozen at
        // whatever it showed when the drag began, for `FlowLayout`'s benefit (see
        // `EditableColorValue.rowScrubPreview`). Only the floating pill sees the live value.
        nsView.onDragChanged = { [weak nsView] newValue in
            guard let nsView else { return }
            // The achieved value, not the requested one: a drag past the sRGB gamut boundary
            // clamps, and the pill must show what the swatch actually is.
            let achieved = onLiveValue(newValue)
            nsView.lastAchievedValue = achieved
        }
        nsView.onDragEnd = { [weak nsView] finalValue in
            guard let nsView else { return }
            text = ColorComponentField.formattedDragValue(
                nsView.lastAchievedValue ?? finalValue, kind: kind, stableDecimalPlaces: nsView.dragDecimalPlaces
            )
            nsView.lastAchievedValue = nil
            onDragEnd()
        }

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
        var onStep: ((CGFloat) -> Void)?

        init(
            text: Binding<String>, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void,
            onStep: ((CGFloat) -> Void)?
        ) {
            self.text = text
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self.onStep = onStep
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? ScrubTextField else { return }
            // Clearing a ranged field (select-all + delete, or backspacing the last digit)
            // leaves it both empty and invalid — effectively a dead end, since an empty
            // `.fixedSize()` field also collapses to no width, hiding the invalid-state dashes
            // that would otherwise show. Snap it to the component's lowest value instead, and
            // select it, so the field stays visible, valid, and ready to be typed straight over
            // — mirroring what a fresh click-to-select does. Hex has no natural minimum
            // (`range` is nil), so it keeps the plain empty/invalid state.
            if field.stringValue.isEmpty, let range = field.range {
                let lowest = ColorComponentField.formattedDragValue(range.lowerBound, kind: field.kind)
                field.stringValue = lowest
                text.wrappedValue = lowest
                if let editor = field.currentEditor() {
                    editor.selectedRange = NSRange(location: 0, length: (lowest as NSString).length)
                }
                return
            }
            text.wrappedValue = field.stringValue
        }

        func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onCancel()
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)), let onStep {
                onStep(1)
                return true
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)), let onStep {
                onStep(-1)
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
/// A resolved click focuses normally; `becomeFirstResponder` then deterministically selects the
/// whole value in the same call stack (matching the click-to-select-all behaviour of a spreadsheet
/// cell), rather than reacting to AppKit's own click-positions-the-caret behaviour after the fact.
final class ScrubTextField: NSTextField {
    var isDraggable = false {
        didSet { window?.invalidateCursorRects(for: self) }
    }

    var range: ClosedRange<Double>?
    var kind: ComponentKind = .integer
    var onDragBegin: (() -> Void)?
    var onDragChanged: ((Double) -> Void)?
    /// Fires with the drag's final value once it ends.
    var onDragEnd: ((Double) -> Void)?
    /// Fires instead of `onDragEnd` when the drag is abandoned with Escape.
    var onDragCancel: (() -> Void)?
    /// Reports true/false as this field becomes/resigns first responder. Driven from these
    /// overrides rather than `NSTextFieldDelegate`'s controlTextDidBeginEditing/EndEditing —
    /// see the note at the `onFocusChange` assignment in `ScrubbableColorField.updateNSView`.
    var onFocusChange: ((Bool) -> Void)?

    /// The most recent value `onDragChanged` reported — always set by the time `finishDrag` can
    /// run, since `updateDrag` fires at least once (immediately after `beginDrag`) before a
    /// `mouseUp` can be reached. Read once, then cleared, to hand `onDragEnd` its final value.
    private var lastDragValue: Double?
    /// Value/x-position the current drag measures its horizontal offset from. Re-anchored
    /// whenever vertical movement changes precision, so rescaling the axis mid-drag doesn't make
    /// the value jump — it just changes how far a pixel moves it from wherever it already is.
    private var dragAnchorValue: Double?
    private var dragAnchorX: CGFloat = 0
    /// Decimal places the drag started at; vertical movement offsets from this, and the
    /// per-pixel step scales inversely so the last shown digit always advances about one per
    /// pixel (otherwise a coarse readout looks frozen while the colour visibly changes).
    private var dragBaseDecimalPlaces = 2
    /// The gamut-clamped value the last drag step actually achieved (see
    /// `EditableColorValue.previewLiveScrub`), so the commit uses reality rather than the raw
    /// requested value. Cleared once the drag ends.
    var lastAchievedValue: Double?
    /// Decimal places to hold this drag's live display at — captured once at drag start (see
    /// `ColorComponentField.stableDecimalPlaces(for:)`) and held fixed for the drag, rather than
    /// recomputed every pixel of movement, so the value's own live-updating string never itself
    /// becomes the thing shifting the row's wrap point mid-drag.
    var dragDecimalPlaces = 2

    // The default NSTextFieldCell intrinsic size proved unreliable once `.fixedSize()` queried
    // it eagerly (fields collapsed to ~0pt wide) — compute it directly from the string and font
    // instead of trusting the cell's own layout pass.
    override var intrinsicContentSize: NSSize {
        let currentFont = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let size = (stringValue as NSString).size(withAttributes: [.font: currentFont])
        return NSSize(width: ceil(size.width) + 2, height: ceil(size.height))
    }

    override func becomeFirstResponder() -> Bool {
        // AppKit's own `_setUpFirstResponder`/`_selectFirstKeyView` auto-focuses the first key
        // view in the window while it's still being ordered onto screen — before it's key —
        // which would open an edit session (and select-all) on the hue field before the user
        // has clicked anything. Reject that call outright; genuine focus (click, Tab, or our
        // own `updateNSView` reconciliation) only ever happens once the window is already key.
        guard window?.isKeyWindow == true else { return false }
        let result = super.becomeFirstResponder()
        if result {
            if let editor = currentEditor() {
                let length = (editor.string as NSString).length
                editor.selectedRange = NSRange(location: 0, length: length)
                // The shared field editor's default `textContainerInset` doesn't match the metrics
                // the static `NSTextFieldCell` used to draw the same string, so the text visibly
                // jumps by a device pixel the instant editing begins. Zero it so the editor draws
                // the text in exactly the same place the cell did.
                if let textView = editor as? NSTextView {
                    textView.textContainerInset = .zero
                }
            }
            window?.invalidateCursorRects(for: self)
            onFocusChange?(true)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            window?.invalidateCursorRects(for: self)
            onFocusChange?(false)
        }
        return result
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.invalidateCursorRects(for: self)
        // Without this, AppKit's own `_setUpFirstResponder`/`_selectFirstKeyView` auto-focuses
        // the first key view in the window (i.e. this field, if it's first in the hierarchy) the
        // moment the window becomes key — opening an edit session on the hue field before the
        // user has clicked anything. `becomeFirstResponder` reports that focus like any other
        // (correctly, so genuine focus changes stay in sync), so SwiftUI accepts it and shows the
        // outline. Steer AppKit's auto-pick to the content view instead, which never becomes an
        // editing session. Harmless to set repeatedly (once per field that attaches).
        if let window, window.initialFirstResponder !== window.contentView {
            window.initialFirstResponder = window.contentView
        }
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
                matching: [.leftMouseDragged, .leftMouseUp, .keyDown],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: true
            ) else {
                if didBeginDrag { finishDrag() }
                return
            }

            switch next.type {
            case .keyDown:
                // Escape abandons the scrub. Only meaningful once a drag is actually under way;
                // otherwise let the key fall through to its normal handling.
                guard didBeginDrag, next.keyCode == 53 else { continue }
                cancelDrag()
                return
            case .leftMouseDragged:
                let translationX = next.locationInWindow.x - startPoint.x
                if !didBeginDrag {
                    guard abs(translationX) >= threshold else { continue }
                    didBeginDrag = true
                    beginDrag(at: next.locationInWindow)
                }
                updateDrag(location: next.locationInWindow, startPoint: startPoint)
            case .leftMouseUp:
                if didBeginDrag {
                    finishDrag()
                } else {
                    // A genuine click: focus normally, exactly like a plain click on any
                    // ordinary text field would. AppKit's own event routing
                    // (`_handleMouseDownEvent:` → `NSTextFieldCell _selectOrEdit:`) already
                    // focuses the field before this override even runs — calling
                    // `makeFirstResponder` again here forces a redundant resign/become pair
                    // that corrupts the field editor's begin-editing bookkeeping, so
                    // `controlTextDidBeginEditing` silently never fires and the field never
                    // reports itself focused to SwiftUI (no outline, no edit session). Once
                    // focused, first responder is the *field editor* (an NSTextView), not this
                    // control itself, so check against `currentEditor()` rather than `self`.
                    let editorIsActive = currentEditor() != nil && window?.firstResponder === currentEditor()
                    if !editorIsActive {
                        window?.makeFirstResponder(self)
                    }
                }
                return
            default:
                if didBeginDrag { finishDrag() }
                return
            }
        }
    }

    private func beginDrag(at location: NSPoint) {
        dragAnchorValue = Double(stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        dragAnchorX = location.x
        // Whichever is finer: the precision this component's drag step can actually resolve, or
        // the precision already on display (so starting a scrub never truncates what's shown).
        dragDecimalPlaces = min(
            Self.precisionRange.upperBound,
            max(
                ColorComponentField.naturalDecimalPlaces(forRange: range),
                ColorComponentField.stableDecimalPlaces(for: stringValue)
            )
        )
        dragBaseDecimalPlaces = dragDecimalPlaces
        NSCursor.resizeLeftRight.set()
        // AppKit's own event routing (`_handleMouseDownEvent:` → `NSTextFieldCell
        // _selectOrEdit:`) already focused and select-all'd this field as part of routing the
        // mouseDown that's turning out to be this drag — before this override's loop could
        // tell click from drag apart. Collapse that selection now that we know it's a drag, so
        // releasing the mouse doesn't leave the dragged-to value shown text-selected. Just the
        // selection, not the focus itself — resigning first responder here would race the
        // deferred focus-loss handling in `EditableColorValue` and could end the drag's edit
        // session (commit/revert) while the user is still mid-drag.
        if let editor = currentEditor() {
            editor.selectedRange = NSRange(location: (editor.string as NSString).length, length: 0)
        }
        onDragBegin?()
    }

    /// Points of vertical travel per decimal place gained or lost.
    private static let pointsPerPrecisionStep: CGFloat = 40
    /// Bounds on scrub precision. Never 0: a 0...1 component (OKLCH chroma) would read a constant
    /// "0" and look broken. 4 matches the widest the normal stripped display ever shows. Not
    /// private: `EditableColorValue`'s scroll-to-scrub path clamps to the same ceiling.
    static let precisionRange = 1 ... 4

    private func updateDrag(location: NSPoint, startPoint: NSPoint) {
        guard dragAnchorValue != nil else { return }

        // Vertical travel picks the precision — dragging down (which decreases y in AppKit's
        // bottom-left window coordinates) reveals more decimals, up rounds them off. Only for
        // `.decimal`; integers have no decimals to trade.
        if kind == .decimal {
            let steps = Int(((startPoint.y - location.y) / Self.pointsPerPrecisionStep).rounded())
            let wanted = min(max(dragBaseDecimalPlaces + steps, Self.precisionRange.lowerBound),
                             Self.precisionRange.upperBound)
            if wanted != dragDecimalPlaces {
                // Re-anchor before rescaling, so only the sensitivity changes, not the value.
                dragAnchorValue = lastDragValue ?? dragAnchorValue
                dragAnchorX = location.x
                dragDecimalPlaces = wanted
            }
        }

        guard let anchorValue = dragAnchorValue else { return }
        let fine = NSEvent.modifierFlags.contains(.option)
        // Scale the per-pixel step against the precision on show, so one pixel moves roughly one
        // unit of the last visible digit at every precision.
        // Only ever *finer* than the drag started: going coarser keeps the original step, so
        // rounding the readout off doesn't also make the drag 10x faster and slam the value into
        // its range bound (chroma pinned at 1.0 renders as magenta, nowhere near the hue shown).
        let scale = pow(10.0, Double(min(0, dragBaseDecimalPlaces - dragDecimalPlaces)))
        let unitsPerStep = dragUnitsPerPixel(for: range) * scale
        var newValue = anchorValue + Double(location.x - dragAnchorX) * unitsPerStep * (fine ? 0.1 : 1.0)
        if let range {
            newValue = min(max(newValue, range.lowerBound), range.upperBound)
        }
        lastDragValue = newValue
        onDragChanged?(newValue)
    }

    private func cancelDrag() {
        dragAnchorValue = nil
        lastDragValue = nil
        NSCursor.arrow.set()
        onDragCancel?()
    }

    private func finishDrag() {
        dragAnchorValue = nil
        NSCursor.arrow.set()
        if let lastDragValue {
            onDragEnd?(lastDragValue)
        }
        lastDragValue = nil
    }
}
