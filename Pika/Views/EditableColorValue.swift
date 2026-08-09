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

    @State private var width: CGFloat = 0
    /// Working component strings. Kept in sync with the colour when idle; owned by the user
    /// while a field is focused.
    @State private var values: [String] = []
    @State private var isEditing = false
    @State private var preEditColor: NSColor?
    /// The colour we last pushed to `eyedropper` ourselves (live preview or commit). Lets
    /// `onChange(of: eyedropper.color)` tell our own writes apart from an external pick landing
    /// mid-edit, so the latter can abort the session instead of being silently overwritten.
    @State private var lastPreviewedColor: NSColor?
    @FocusState private var focusedIndex: Int?

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
                    onCancel: revertEditing
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
        .onChange(of: format) { _ in if !isEditing { syncValuesFromColor(decomposed) } }
        .onChange(of: style) { _ in if !isEditing { syncValuesFromColor(decomposed) } }
    }

    private func affix(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(Color(uiColor).opacity(0.5))
    }

    // MARK: - Values ↔ colour

    private func syncValuesFromColor(_ layout: DecomposedColor) {
        values = layout.values
    }

    private func binding(for index: Int, layout: DecomposedColor) -> Binding<String> {
        Binding(
            get: { index < values.count ? values[index] : layout.values[index] },
            set: { newValue in
                if values.count != layout.components.count { values = layout.values }
                guard index < values.count else { return }
                values[index] = newValue
                previewIfValid(layout: layout)
            }
        )
    }

    // MARK: - Editing lifecycle

    private func handleFocusChange(to newValue: Int?, layout: DecomposedColor) {
        if newValue != nil {
            // Entering (or moving between) fields — start a session on the first focus.
            if !isEditing {
                isEditing = true
                preEditColor = eyedropper.color
                values = layout.values
            }
        } else if isEditing {
            // Focus left every field (blur / tab-out) — commit if valid, otherwise revert.
            finishEditing()
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
        values = decomposed.values
    }
}

/// A single focusable numeric/hex field styled to the swatch's UI colour, with the four design
/// states: default (bare), hover (filled), focus (outlined), invalid (dashed outline).
private struct ColorComponentField: View {
    @Binding var text: String
    let component: ColorComponent
    let index: Int
    let uiColor: NSColor
    let fontSize: CGFloat
    @FocusState.Binding var focusedIndex: Int?
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var isHovering = false

    private var isFocused: Bool { focusedIndex == index }
    private var isInvalid: Bool { isFocused && !component.isValid(text) }

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundStyle(Color(uiColor))
            .fixedSize()
            .multilineTextAlignment(.center)
            .focused($focusedIndex, equals: index)
            .onSubmit(onSubmit)
            .onExitCommand(perform: onCancel)
            .padding(.horizontal, 3)
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
            .onHover { isHovering = $0 }
            .animation(.easeInOut(duration: 0.12), value: isHovering)
            .animation(.easeInOut(duration: 0.12), value: isFocused)
    }
}
