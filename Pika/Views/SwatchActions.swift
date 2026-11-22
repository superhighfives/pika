import Defaults
import SwiftUI

/// The quiet controls after a colour's value: Copy, Pick and ⋯. Drawn in the label's own ink with
/// no background, so nothing but the floating bar sits on the colour as glass.
struct SwatchActionIcons: View {
    @ObservedObject var eyedropper: Eyedropper
    /// Shown while the colour is hovered. Kept in the layout either way, so the value doesn't
    /// move as they appear.
    var isVisible: Bool
    var onHoverChange: (Bool) -> Void = { _ in }

    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @State private var copied = false
    @State private var copiedTask: Task<Void, Never>?

    private var ink: Color { Color(eyedropper.color.getUIColor()).opacity(0.7) }

    var body: some View {
        HStack(spacing: 10.0) {
            iconButton(copied ? "checkmark" : "doc.on.doc", label: PikaText.textColorCopy) {
                // Copied here rather than through the copy action, which also shows the toast:
                // the tick on the icon is the feedback for a click. ⌘C keeps the toast.
                NSPasteboard.general.setColorString(eyedropper.color.toFormat(format: colorFormat, style: copyFormat))
                showCopied()
            }
            iconButton("eyedropper", label: eyedropper.type.pickTitle) {
                NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil)
            }
            Menu {
                SwatchActionsMenu(eyedropper: eyedropper)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            // A plain button style, so the label keeps the ink: the borderless menu style drew it
            // in its own colour, white even on light colours.
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(PikaText.textSwatchActions(eyedropper.type))
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .animation(.easeInOut(duration: 0.15), value: isVisible)
        .onHover(perform: onHoverChange)
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(label)
        .accessibilityLabel(label)
    }

    /// The copy icon turns into a tick for a moment, in place of a toast.
    private func showCopied() {
        copiedTask?.cancel()
        withAnimation { copied = true }
        copiedTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation { copied = false }
        }
    }
}

/// Every action for one colour. Shared by the ⋯ button and the right-click menu, so they can't
/// drift apart, and each item shows its shortcut so the menu also teaches them.
struct SwatchActionsMenu: View {
    @ObservedObject var eyedropper: Eyedropper
    @Default(.copyFormat) private var copyFormat

    /// The background's shortcuts add ⇧ to the foreground's.
    private var modifiers: EventModifiers {
        eyedropper.type == .foreground ? .command : [.command, .shift]
    }

    var body: some View {
        Button(eyedropper.type.copyTitle) {
            NSApp.sendAction(eyedropper.type.copySelector, to: nil, from: nil)
        }
        .keyboardShortcut("c", modifiers: modifiers)

        Menu(PikaText.textColorCopyAs) {
            ForEach(ColorFormat.allCases, id: \.self) { format in
                Button(format.rawValue) { copy(as: format) }
            }
        }

        Button(eyedropper.type.pasteTitle) {
            NSApp.sendAction(eyedropper.type.pasteSelector, to: nil, from: nil)
        }
        .keyboardShortcut("v", modifiers: modifiers)

        Divider()

        Button(eyedropper.type.pickTitle) {
            NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil)
        }
        .keyboardShortcut("d", modifiers: modifiers)

        Button(PikaText.textColorSystemPicker) {
            NSApp.sendAction(eyedropper.type.systemPickerSelector, to: nil, from: nil)
        }
        .keyboardShortcut("s", modifiers: modifiers)
    }

    /// Copies in a format other than the one shown, without changing the shown format.
    private func copy(as format: ColorFormat) {
        NSPasteboard.general.setColorString(eyedropper.color.toFormat(format: format, style: copyFormat))
    }
}

extension NSPasteboard {
    /// Replaces the pasteboard's contents with a colour's value, as plain text.
    func setColorString(_ value: String) {
        clearContents()
        setString(value, forType: .string)
    }
}

extension Eyedropper.Types {
    var copyTitle: String {
        self == .foreground ? PikaText.textCopyForeground : PikaText.textCopyBackground
    }

    var pasteTitle: String {
        self == .foreground ? PikaText.textPasteForeground : PikaText.textPasteBackground
    }

    var pickTitle: String {
        self == .foreground ? PikaText.textPickForeground : PikaText.textPickBackground
    }

    var pasteSelector: Selector {
        self == .foreground
            ? #selector(AppDelegate.triggerPasteForeground)
            : #selector(AppDelegate.triggerPasteBackground)
    }
}

extension View {
    /// The pointing hand over a pick area, the system's own "click here". On macOS 15 and later
    /// SwiftUI owns the pointer, which holds where a cursor set from AppKit was reset after a
    /// moment; macOS 14 pushes the hand on hover instead (`EyedropperButton`).
    @ViewBuilder func pickPointer() -> some View {
        if #available(macOS 15, *) {
            pointerStyle(.link)
        } else {
            self
        }
    }

    /// The ordinary arrow, for controls that sit over a pick area but don't pick. macOS 14 sets
    /// it on hover, over the pointing hand the pick area pushed.
    @ViewBuilder func defaultPointer() -> some View {
        if #available(macOS 15, *) {
            pointerStyle(.default)
        } else {
            onHover { inside in if inside { NSCursor.arrow.set() } }
        }
    }
}
