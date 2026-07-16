import AppKit
import Foundation

/// Single source of truth for Pika's keyboard shortcuts. Used by:
/// - `KeyboardShortcutGrid` (Help view) for visual display
/// - `AppDelegate.popoverShortcutAction(for:)` to dispatch shortcuts in popover mode,
///   where neither `NSApp.mainMenu.performKeyEquivalent` nor SwiftUI's `.commands`
///   `.keyboardShortcut` bindings reach the popover panel.
struct PikaShortcut {
    let title: String
    let displayKeys: [String]
    let character: String
    let modifiers: NSEvent.ModifierFlags
    let action: Selector
    let notificationName: Notification.Name
}

enum PikaShortcuts {
    static let all: [PikaShortcut] = [
        PikaShortcut(
            title: PikaText.textPickForeground,
            displayKeys: ["⌘", "D"], character: "d", modifiers: .command,
            action: #selector(AppDelegate.triggerPickForeground),
            notificationName: .triggerPickForeground
        ),
        PikaShortcut(
            title: PikaText.textPickBackground,
            displayKeys: ["⇧", "⌘", "D"], character: "d", modifiers: [.command, .shift],
            action: #selector(AppDelegate.triggerPickBackground),
            notificationName: .triggerPickBackground
        ),
        PikaShortcut(
            title: PikaText.textCopyForeground,
            displayKeys: ["⌘", "C"], character: "c", modifiers: .command,
            action: #selector(AppDelegate.triggerCopyForeground),
            notificationName: .triggerCopyForeground
        ),
        PikaShortcut(
            title: PikaText.textCopyBackground,
            displayKeys: ["⇧", "⌘", "C"], character: "c", modifiers: [.command, .shift],
            action: #selector(AppDelegate.triggerCopyBackground),
            notificationName: .triggerCopyBackground
        ),
        PikaShortcut(
            title: PikaText.textColorSystemPickerForegroundSimple,
            displayKeys: ["⌘", "S"], character: "s", modifiers: .command,
            action: #selector(AppDelegate.triggerSystemPickerForeground),
            notificationName: .triggerSystemPickerForeground
        ),
        PikaShortcut(
            title: PikaText.textColorSystemPickerBackgroundSimple,
            displayKeys: ["⇧", "⌘", "S"], character: "s", modifiers: [.command, .shift],
            action: #selector(AppDelegate.triggerSystemPickerBackground),
            notificationName: .triggerSystemPickerBackground
        ),
        PikaShortcut(
            title: PikaText.textColorUndo,
            displayKeys: ["⌘", "Z"], character: "z", modifiers: .command,
            action: #selector(AppDelegate.triggerUndo),
            notificationName: .triggerUndo
        ),
        PikaShortcut(
            title: PikaText.textColorRedo,
            displayKeys: ["⇧", "⌘", "Z"], character: "z", modifiers: [.command, .shift],
            action: #selector(AppDelegate.triggerRedo),
            notificationName: .triggerRedo
        ),
        PikaShortcut(
            title: PikaText.textColorSwapDetail,
            displayKeys: ["X"], character: "x", modifiers: [],
            action: #selector(AppDelegate.triggerSwap),
            notificationName: .triggerSwap
        ),
        PikaShortcut(
            title: PikaText.textHistoryToggle,
            displayKeys: ["H"], character: "h", modifiers: [],
            action: #selector(AppDelegate.triggerToggleHistory),
            notificationName: .toggleHistory
        ),
        PikaShortcut(
            title: "\(PikaText.textMenuPreferences)...",
            displayKeys: ["⌘", ","], character: ",", modifiers: .command,
            action: #selector(AppDelegate.openPreferencesWindow),
            notificationName: .triggerPreferences
        ),
        PikaShortcut(
            title: PikaText.textMenuQuit,
            displayKeys: ["⌘", "Q"], character: "q", modifiers: .command,
            action: #selector(AppDelegate.terminatePika),
            notificationName: .triggerQuit
        ),
        PikaShortcut(
            title: PikaText.textFormatHex,
            displayKeys: ["⌘", "1"], character: "1", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatHex),
            notificationName: .triggerFormatHex
        ),
        PikaShortcut(
            title: PikaText.textFormatRGB,
            displayKeys: ["⌘", "2"], character: "2", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatRGB),
            notificationName: .triggerFormatRGB
        ),
        PikaShortcut(
            title: PikaText.textFormatHSB,
            displayKeys: ["⌘", "3"], character: "3", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatHSB),
            notificationName: .triggerFormatHSB
        ),
        PikaShortcut(
            title: PikaText.textFormatHSL,
            displayKeys: ["⌘", "4"], character: "4", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatHSL),
            notificationName: .triggerFormatHSL
        ),
        PikaShortcut(
            title: PikaText.textFormatLAB,
            displayKeys: ["⌘", "5"], character: "5", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatLAB),
            notificationName: .triggerFormatLAB
        ),
        PikaShortcut(
            title: PikaText.textFormatOpenGL,
            displayKeys: ["⌘", "6"], character: "6", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatOpenGL),
            notificationName: .triggerFormatOpenGL
        ),
        PikaShortcut(
            title: PikaText.textFormatOKLCH,
            displayKeys: ["⌘", "7"], character: "7", modifiers: .command,
            action: #selector(AppDelegate.triggerFormatOKLCH),
            notificationName: .triggerFormatOKLCH
        ),
    ]

    /// Returns the shortcut matching the given key event, if any.
    static func match(_ event: NSEvent) -> PikaShortcut? {
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return all.first { $0.character == chars && $0.modifiers == mods }
    }
}
