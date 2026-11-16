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

    @State private var copied = false
    @State private var copiedTask: Task<Void, Never>?

    private var ink: Color { Color(eyedropper.color.getUIColor()).opacity(0.7) }

    var body: some View {
        HStack(spacing: 10.0) {
            iconButton(copied ? "checkmark" : "doc.on.doc", label: PikaText.textColorCopy) {
                NSApp.sendAction(eyedropper.type.copySelector, to: nil, from: nil)
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
            .menuStyle(.borderlessButton)
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
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(eyedropper.color.toFormat(format: format, style: copyFormat), forType: .string)
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

/// The cursor over a colour's pick area: an eyedropper, which is the hint that a click picks.
/// Drawn from the SF Symbol in white with a dark outline so it reads on any colour, with its
/// hotspot at the tip.
enum EyedropperCursor {
    static let shared: NSCursor = {
        let size: CGFloat = 20
        let config = NSImage.SymbolConfiguration(pointSize: size - 4, weight: .semibold)
        guard let symbol = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        else { return .crosshair }

        func tinted(_ color: NSColor) -> NSImage {
            let image = NSImage(size: symbol.size)
            image.lockFocus()
            symbol.draw(in: NSRect(origin: .zero, size: symbol.size))
            color.set()
            NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
            image.unlockFocus()
            return image
        }

        let outline = tinted(.black)
        let fill = tinted(.white)
        let canvas = NSSize(width: symbol.size.width + 4, height: symbol.size.height + 4)
        let image = NSImage(size: canvas)
        image.lockFocus()
        for dx in [-1.0, 0, 1] {
            for dy in [-1.0, 0, 1] where dx != 0 || dy != 0 {
                outline.draw(at: NSPoint(x: 2 + dx, y: 2 + dy), from: .zero, operation: .sourceOver, fraction: 0.9)
            }
        }
        fill.draw(at: NSPoint(x: 2, y: 2), from: .zero, operation: .sourceOver, fraction: 1)
        image.unlockFocus()
        // The symbol's tip is its bottom-left corner; cursor hotspots count down from the top.
        return NSCursor(image: image, hotSpot: NSPoint(x: 3, y: canvas.height - 3))
    }()
}
