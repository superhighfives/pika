import Defaults
import SwiftUI

/// Wraps NSTextView because SwiftUI's TextEditor lacks control over autocorrect,
/// smart quotes, and text container insets on macOS.
struct PaletteTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: (() -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.string = text
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context _: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PaletteTextView
        init(_ parent: PaletteTextView) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.onTextChange?()
        }
    }
}

struct PaletteEditor: View {
    @Default(.paletteText) var paletteText
    @State private var saveStatus: String?
    @State private var debounceWorkItem: DispatchWorkItem?
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    // swiftlint:disable line_length
    private let exampleText = "[Babel Fish]\n#FFD700(Gold), #FF6B35(Tangerine), #FFA500(Amber)\n\n[Pan Galactic Gargle Blaster]\nrgb(8, 247, 254), oklch(64% 0.2440 349), hsl(49, 97%, 48%)"
    // swiftlint:enable line_length

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Section(
                header: Text(PikaText.textPalettesTitle).font(
                    .system(size: 16))
            ) {
                VStack(alignment: .leading, spacing: 12.0) {
                    Text(PikaText.textPalettesSync).font(
                        .system(size: 13, weight: .medium))

                    Text(exampleText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8.0)
                        .padding(.vertical, 8.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 4.0))
                        .background(RoundedRectangle(cornerRadius: 4.0).fill(
                            colorScheme == .dark
                                ? .black.opacity(0.1)
                                : .white.opacity(0.2)
                        ))
                        .overlay(RoundedRectangle(cornerRadius: 4.0)
                            .stroke(Color.primary.opacity(0.1)))

                    PaletteTextView(text: $paletteText) {
                        triggerSaveStatus()
                    }
                    .frame(height: 120)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4.0))
                    .overlay(RoundedRectangle(cornerRadius: 4.0)
                        .stroke(Color.primary.opacity(0.1)))

                    Text(saveStatus ?? " ")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .opacity(saveStatus != nil ? 1 : 0)
                }
            }
        }
    }

    /// Debounces validation + "Saved" feedback so it doesn't flash on every keystroke.
    private func triggerSaveStatus() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem {
            let warning = PaletteParser.validate(paletteText)
            withAnimation(.easeInOut(duration: 0.2)) {
                saveStatus = warning ?? "Saved"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    saveStatus = nil
                }
            }
        }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}
