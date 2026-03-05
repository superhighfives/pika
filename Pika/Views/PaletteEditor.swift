import Defaults
import SwiftUI

/// NSTextView subclass that handles standard edit shortcuts directly,
/// bypassing the app's custom Edit menu which lacks Cut/Copy/Paste items.
class PasteableTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        switch event.charactersIgnoringModifiers {
        case "v": pasteAsPlainText(nil); return true
        case "c": copy(nil); return true
        case "x": cut(nil); return true
        case "a": selectAll(nil); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }
}

/// Wraps NSTextView because SwiftUI's TextEditor lacks control over autocorrect,
/// smart quotes, and text container insets on macOS.
struct PaletteTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: (() -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PasteableTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.string = text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.documentView = textView
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
    @State private var statusText: String = ""
    @State private var statusOpacity: Double = 1.0
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var fadeWorkItem: DispatchWorkItem?
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    // swiftlint:disable line_length
    private let exampleText = "[Pika]\n#7939F0, #D85685, #020202\n\n[Pika named]\n#7939F0(Primary), #D85685(Seconday), #020202(Background)\n\n[Pika any format]\nrgb(121, 57, 240), hsl(338, 63%, 59%), oklch(8.47% 0.0000 89.88)"
    // swiftlint:enable line_length

    private var syncManager: PaletteSyncManager? {
        (NSApp.delegate as? AppDelegate)?.paletteSyncManager
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Section(
                header: Text(PikaText.textPalettesTitle).font(
                    .system(size: 16))
            ) {
                VStack(alignment: .leading, spacing: 12.0) {
                    Text(PikaText.textPalettesDescription).font(
                        .system(size: 13, weight: .medium))

                    PaletteTextView(text: $paletteText) {
                        onTextEdited()
                    }
                    .frame(height: 120)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4.0))
                    .overlay(RoundedRectangle(cornerRadius: 4.0)
                        .stroke(Color.primary.opacity(0.1)))

                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .opacity(statusOpacity)
                        .animation(.easeInOut(duration: 0.3), value: statusOpacity)

                    VStack(alignment: .leading, spacing: 6.0) {
                        Text("Example")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(exampleText)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
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
                }
            }
        }
        .onAppear { statusText = restingStatus() }
    }

    /// Called on each text edit. Debounces, then shows "Saved" briefly before
    /// fading through transparent back to the resting status.
    private func onTextEdited() {
        debounceWorkItem?.cancel()
        fadeWorkItem?.cancel()

        let work = DispatchWorkItem {
            let resting = restingStatus()

            // If there are validation warnings, show them immediately (no "Saved" flash).
            if let warning = PaletteParser.validate(paletteText) {
                transitionStatus(to: warning)
                return
            }

            // Flash "Saved" then fade back to resting status.
            transitionStatus(to: "Saved") {
                let fade = DispatchWorkItem {
                    transitionStatus(to: resting)
                }
                fadeWorkItem = fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: fade)
            }
        }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    /// Fades out, swaps text, fades in. Calls completion after fade-in.
    private func transitionStatus(to newText: String, completion: (() -> Void)? = nil) {
        // Fade out
        withAnimation(.easeInOut(duration: 0.25)) {
            statusOpacity = 0.0
        }
        // Swap text and fade in after fade-out completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            statusText = newText
            withAnimation(.easeInOut(duration: 0.25)) {
                statusOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion?()
            }
        }
    }

    /// The permanent resting message based on iCloud state.
    private func restingStatus() -> String {
        guard let manager = syncManager else {
            return "Saved locally"
        }
        if !manager.iCloudAvailable {
            return "iCloud unavailable"
        }
        if manager.quotaExceeded {
            return "iCloud quota exceeded"
        }
        return "Synced via iCloud"
    }
}
