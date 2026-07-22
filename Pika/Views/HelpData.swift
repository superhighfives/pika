import SwiftUI

// MARK: - Keyboard Shortcuts

typealias ShortcutGroup = (title: String, entries: [ShortcutEntry])

let shortcutGroups: [ShortcutGroup] = [
    ("Pick", [
        ShortcutEntry(title: PikaText.textPickForeground, keys: ["⌘", "D"], notificationName: .triggerPickForeground),
        ShortcutEntry(title: PikaText.textPickBackground, keys: ["⇧", "⌘", "D"], notificationName: .triggerPickBackground),
    ]),
    ("Copy", [
        ShortcutEntry(title: PikaText.textCopyForeground, keys: ["⌘", "C"], notificationName: .triggerCopyForeground),
        ShortcutEntry(title: PikaText.textCopyBackground, keys: ["⇧", "⌘", "C"], notificationName: .triggerCopyBackground),
    ]),
    (PikaText.textColorSystemPicker, [
        ShortcutEntry(title: PikaText.textColorSystemPickerForegroundSimple, keys: ["⌘", "S"], notificationName: .triggerSystemPickerForeground),
        ShortcutEntry(title: PikaText.textColorSystemPickerBackgroundSimple, keys: ["⇧", "⌘", "S"], notificationName: .triggerSystemPickerBackground),
    ]),
    ("Change Format", [
        ShortcutEntry(title: PikaText.textFormatHex, keys: ["⌘", "1"], notificationName: .triggerFormatHex),
        ShortcutEntry(title: PikaText.textFormatRGB, keys: ["⌘", "2"], notificationName: .triggerFormatRGB),
        ShortcutEntry(title: PikaText.textFormatHSB, keys: ["⌘", "3"], notificationName: .triggerFormatHSB),
        ShortcutEntry(title: PikaText.textFormatHSL, keys: ["⌘", "4"], notificationName: .triggerFormatHSL),
        ShortcutEntry(title: PikaText.textFormatLAB, keys: ["⌘", "5"], notificationName: .triggerFormatLAB),
        ShortcutEntry(title: PikaText.textFormatOpenGL, keys: ["⌘", "6"], notificationName: .triggerFormatOpenGL),
        ShortcutEntry(title: PikaText.textFormatOKLCH, keys: ["⌘", "7"], notificationName: .triggerFormatOKLCH),
    ]),
    ("Actions", [
        ShortcutEntry(title: PikaText.textColorSwapDetail, keys: ["X"], notificationName: .triggerSwap),
        ShortcutEntry(title: PikaText.textHistoryToggle, keys: ["H"], notificationName: .toggleHistory),
        ShortcutEntry(title: PikaText.textComplianceToggle, keys: ["C"], notificationName: .toggleCompliance),
        ShortcutEntry(title: PikaText.textColorPreviewToggle, keys: ["P"], notificationName: .toggleColorPreview),
        ShortcutEntry(title: PikaText.textColorUndo, keys: ["⌘", "Z"], notificationName: .triggerUndo),
        ShortcutEntry(title: PikaText.textColorRedo, keys: ["⇧", "⌘", "Z"], notificationName: .triggerRedo),
        ShortcutEntry(title: "\(PikaText.textMenuPreferences)…", keys: ["⌘", ","], notificationName: .triggerPreferences),
        ShortcutEntry(title: PikaText.textMenuQuit, keys: ["⌘", "Q"], notificationName: nil),
    ]),
]

// MARK: - URL Triggers

typealias URLGroup = (title: String, entries: [(url: String, description: String)])

let urlGroups: [URLGroup] = [
    (PikaText.textUrlGroupPick, [
        ("pika://pick/foreground", PikaText.textPickForeground),
        ("pika://pick/background", PikaText.textPickBackground),
        ("pika://pick/contrast", PikaText.textPickContrast),
    ]),
    (PikaText.textColorSystemPicker, [
        ("pika://system/foreground", PikaText.textColorSystemPickerForegroundSimple),
        ("pika://system/background", PikaText.textColorSystemPickerBackgroundSimple),
    ]),
    (PikaText.textUrlGroupCopy, [
        ("pika://copy/foreground", PikaText.textCopyForeground),
        ("pika://copy/background", PikaText.textCopyBackground),
        ("pika://copy/text", PikaText.textMenuCopyAllAsText),
        ("pika://copy/json", PikaText.textMenuCopyAllAsJSON),
    ]),
    (PikaText.textUrlGroupChangeFormat, [
        ("pika://format/hex", PikaText.textFormatHex),
        ("pika://format/rgb", PikaText.textFormatRGB),
        ("pika://format/hsb", PikaText.textFormatHSB),
        ("pika://format/hsl", PikaText.textFormatHSL),
        ("pika://format/lab", PikaText.textFormatLAB),
        ("pika://format/opengl", PikaText.textFormatOpenGL),
        ("pika://format/oklch", PikaText.textFormatOKLCH),
    ]),
    (PikaText.textUrlGroupActions, [
        ("pika://swap", PikaText.textColorSwapDetail),
        ("pika://undo", PikaText.textColorUndo),
        ("pika://redo", PikaText.textColorRedo),
    ]),
    (PikaText.textUrlGroupSetColor, [
        ("pika://set/foreground/<hex>", PikaText.textUrlSetForeground),
        ("pika://set/background/<hex>", PikaText.textUrlSetBackground),
    ]),
    (PikaText.textUrlGroupHistory, [
        ("pika://history/show", PikaText.textUrlHistoryShow),
        ("pika://history/hide", PikaText.textUrlHistoryHide),
        ("pika://history/toggle", PikaText.textUrlHistoryToggle),
    ]),
    (PikaText.textUrlGroupCompliance, [
        ("pika://compliance/show", PikaText.textUrlComplianceShow),
        ("pika://compliance/hide", PikaText.textUrlComplianceHide),
        ("pika://compliance/toggle", PikaText.textUrlComplianceToggle),
    ]),
    (PikaText.textUrlGroupPreview, [
        ("pika://preview/show", PikaText.textUrlPreviewShow),
        ("pika://preview/hide", PikaText.textUrlPreviewHide),
        ("pika://preview/toggle", PikaText.textUrlPreviewToggle),
    ]),
    (PikaText.textUrlGroupWindow, [
        ("pika://window/about", PikaText.textUrlWindowAbout),
        ("pika://window/help", PikaText.textUrlWindowHelp),
        ("pika://window/preferences", PikaText.textUrlWindowPreferences),
        ("pika://window/splash", PikaText.textUrlWindowSplash),
        ("pika://window/resize/<w>/<h>", PikaText.textUrlWindowResize),
    ]),
    (PikaText.textUrlGroupAppearance, [
        ("pika://appearance/light", PikaText.textUrlAppearanceLight),
        ("pika://appearance/dark", PikaText.textUrlAppearanceDark),
        ("pika://appearance/system", PikaText.textUrlAppearanceSystem),
    ]),
]

// MARK: - Colour Formats

struct HelpFormat {
    let name: String
    let example: String
    let shortcut: String
}

let formats: [HelpFormat] = [
    HelpFormat(name: PikaText.textFormatHex, example: "#8F0FD0", shortcut: "1"),
    HelpFormat(name: PikaText.textFormatRGB, example: "143, 15, 208", shortcut: "2"),
    HelpFormat(name: PikaText.textFormatHSB, example: "277°, 93%, 82%", shortcut: "3"),
    HelpFormat(name: PikaText.textFormatHSL, example: "277°, 86%, 44%", shortcut: "4"),
    HelpFormat(name: PikaText.textFormatLAB, example: "36, 62, −69", shortcut: "5"),
    HelpFormat(name: PikaText.textFormatOpenGL, example: "0.56, 0.06, 0.82", shortcut: "6"),
    HelpFormat(name: PikaText.textFormatOKLCH, example: "0.45, 0.24, 299°", shortcut: "7"),
]
