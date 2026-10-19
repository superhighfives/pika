import KeyboardShortcuts
import SwiftUI

// MARK: - Basics

struct HelpBasic {
    let symbol: String
    /// Matches the colour of the same concept on the website's Pika and Help pages:
    /// Tailwind's 600 shade in light mode and 400 in dark, like the site's feature titles.
    let tint: (light: Color, dark: Color)
    let title: String
    let text: String
}

let basics: [HelpBasic] = [
    HelpBasic(
        symbol: "square.on.square",
        tint: (light: Color(red: 0.008, green: 0.518, blue: 0.780), dark: Color(red: 0.220, green: 0.741, blue: 0.973)),
        title: PikaText.textHelpBasicsPairTitle, text: PikaText.textHelpBasicsPair
    ),
    HelpBasic(
        symbol: "eye",
        tint: (light: Color(red: 0.859, green: 0.153, blue: 0.467), dark: Color(red: 0.957, green: 0.447, blue: 0.714)),
        title: PikaText.textHelpBasicsContrastTitle, text: PikaText.textHelpBasicsContrast
    ),
    HelpBasic(
        symbol: "textformat.size",
        tint: (light: Color(red: 0.310, green: 0.275, blue: 0.898), dark: Color(red: 0.506, green: 0.549, blue: 0.973)),
        title: PikaText.textHelpBasicsStandardsTitle, text: PikaText.textHelpBasicsStandards
    ),
    HelpBasic(
        symbol: "eyedropper",
        tint: (light: Color(red: 0.753, green: 0.149, blue: 0.827), dark: Color(red: 0.910, green: 0.475, blue: 0.976)),
        title: PikaText.textHelpBasicsPickersTitle, text: PikaText.textHelpBasicsPickers
    ),
    HelpBasic(
        symbol: "slider.horizontal.3",
        tint: (light: Color(red: 0.863, green: 0.149, blue: 0.149), dark: Color(red: 0.973, green: 0.443, blue: 0.443)),
        title: PikaText.textHelpBasicsEditingTitle, text: PikaText.textHelpBasicsEditing
    ),
    HelpBasic(
        symbol: "paintpalette",
        tint: (light: Color(red: 0.851, green: 0.467, blue: 0.024), dark: Color(red: 0.984, green: 0.749, blue: 0.141)),
        title: PikaText.textHelpBasicsSpacesTitle, text: PikaText.textHelpBasicsSpaces
    ),
]

// MARK: - Keyboard Shortcuts

typealias ShortcutGroup = (title: String, entries: [ShortcutEntry])

/// Splits a shortcut like "⌥⌘D" into key caps: each modifier on its own, then the key.
func keyCaps(for shortcut: String) -> [String] {
    let modifiers = shortcut.prefix { "⌃⌥⇧⌘".contains($0) }
    let key = shortcut.dropFirst(modifiers.count)
    return modifiers.map(String.init) + (key.isEmpty ? [] : [String(key)])
}

/// The Pick pair shortcut as key caps, following the user's binding in Settings (⌥⌘D by default).
@MainActor
func pickPairKeys() -> [String] {
    guard let shortcut = KeyboardShortcuts.getShortcut(for: .pickPair) else { return [] }
    return keyCaps(for: shortcut.description)
}

@MainActor
var shortcutGroups: [ShortcutGroup] { [
    (PikaText.textUrlGroupPick, [
        ShortcutEntry(title: PikaText.textPickForeground, keys: ["⌘", "D"], notificationName: .triggerPickForeground),
        ShortcutEntry(title: PikaText.textPickBackground, keys: ["⇧", "⌘", "D"], notificationName: .triggerPickBackground),
        ShortcutEntry(title: PikaText.textPickContrast, keys: pickPairKeys(), notificationName: .triggerPickPair),
    ]),
    (PikaText.textUrlGroupCopy, [
        ShortcutEntry(title: PikaText.textCopyForeground, keys: ["⌘", "C"], notificationName: .triggerCopyForeground),
        ShortcutEntry(title: PikaText.textCopyBackground, keys: ["⇧", "⌘", "C"], notificationName: .triggerCopyBackground),
    ]),
    (PikaText.textColorSystemPicker, [
        ShortcutEntry(title: PikaText.textColorSystemPickerForegroundSimple, keys: ["⌘", "S"], notificationName: .triggerSystemPickerForeground),
        ShortcutEntry(title: PikaText.textColorSystemPickerBackgroundSimple, keys: ["⇧", "⌘", "S"], notificationName: .triggerSystemPickerBackground),
    ]),
    (PikaText.textUrlGroupChangeFormat, [
        ShortcutEntry(title: PikaText.textFormatHex, keys: ["⌘", "1"], notificationName: .triggerFormatHex),
        ShortcutEntry(title: PikaText.textFormatRGB, keys: ["⌘", "2"], notificationName: .triggerFormatRGB),
        ShortcutEntry(title: PikaText.textFormatHSB, keys: ["⌘", "3"], notificationName: .triggerFormatHSB),
        ShortcutEntry(title: PikaText.textFormatHSL, keys: ["⌘", "4"], notificationName: .triggerFormatHSL),
        ShortcutEntry(title: PikaText.textFormatLAB, keys: ["⌘", "5"], notificationName: .triggerFormatLAB),
        ShortcutEntry(title: PikaText.textFormatOpenGL, keys: ["⌘", "6"], notificationName: .triggerFormatOpenGL),
        ShortcutEntry(title: PikaText.textFormatOKLCH, keys: ["⌘", "7"], notificationName: .triggerFormatOKLCH),
    ]),
    (PikaText.textUrlGroupActions, [
        ShortcutEntry(title: PikaText.textColorSwapDetail, keys: ["X"], notificationName: .triggerSwap),
        ShortcutEntry(title: PikaText.textHistoryToggle, keys: ["H"], notificationName: .toggleHistory),
        ShortcutEntry(title: PikaText.textComplianceToggle, keys: ["C"], notificationName: .toggleCompliance),
        ShortcutEntry(title: PikaText.textColorPreviewToggle, keys: ["P"], notificationName: .toggleColorPreview),
        ShortcutEntry(title: PikaText.textColorUndo, keys: ["⌘", "Z"], notificationName: .triggerUndo),
        ShortcutEntry(title: PikaText.textColorRedo, keys: ["⇧", "⌘", "Z"], notificationName: .triggerRedo),
        ShortcutEntry(title: "\(PikaText.textMenuPreferences)…", keys: ["⌘", ","], notificationName: .triggerPreferences),
        ShortcutEntry(title: PikaText.textMenuQuit, keys: ["⌘", "Q"], notificationName: nil),
    ]),
] }

// MARK: - URL Triggers

typealias URLGroup = (title: String, entries: [(url: String, description: String)])

let urlGroups: [URLGroup] = [
    (PikaText.textUrlGroupPick, [
        ("pika://pick/foreground", PikaText.textPickForeground),
        ("pika://pick/background", PikaText.textPickBackground),
        ("pika://pick/contrast", PikaText.textPickContrast),
        ("pika://pick/foreground/<format>", PikaText.textUrlPickForegroundFormat),
        ("pika://pick/background/<format>", PikaText.textUrlPickBackgroundFormat),
    ]),
    (PikaText.textColorSystemPicker, [
        ("pika://system/foreground", PikaText.textColorSystemPickerForegroundSimple),
        ("pika://system/background", PikaText.textColorSystemPickerBackgroundSimple),
    ]),
    (PikaText.textUrlGroupCopy, [
        ("pika://copy/foreground", PikaText.textCopyForeground),
        ("pika://copy/background", PikaText.textCopyBackground),
        ("pika://copy/foreground/<format>", PikaText.textUrlCopyForegroundFormat),
        ("pika://copy/background/<format>", PikaText.textUrlCopyBackgroundFormat),
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
