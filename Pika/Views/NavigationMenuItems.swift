import Defaults
import SwiftUI

struct MenuGroup<Content>: View where Content: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Menu(title) {
            content()
        }
    }
}

/// One action in Pika's action menus: the toolbar's More menu and the status item's right-click
/// menu. Both are built from `PikaMenu.entries`, so they offer the same actions, names and
/// shortcuts; they used to be written separately and drifted (Paste was only in More).
struct PikaMenuAction {
    /// The title in a submenu, or at the top level.
    let title: String
    /// The title when its submenu is laid out flat, as in the right-click menu ("Copy
    /// Foreground" rather than "Copy › Foreground"). Defaults to `title`.
    var flatTitle: String?
    let action: Selector
    var key: String = ""
    var modifiers: NSEvent.ModifierFlags = .command
    /// Only in the More menu: things about the window (Undo, Redo), not quick actions.
    var windowOnly = false
}

enum PikaMenuEntry {
    case action(PikaMenuAction)
    /// A submenu in More, laid out flat between dividers in the right-click menu.
    case group(String, [PikaMenuEntry])
    case divider
    /// New and Export Palette, which follow the drawer's state; only in More.
    case palettes
}

enum PikaMenu {
    private static func pair(
        flat foreground: String, _ background: String, action fgAction: Selector, _ bgAction: Selector, key: String
    ) -> [PikaMenuEntry] {
        [
            .action(PikaMenuAction(title: PikaText.textColorForeground, flatTitle: foreground,
                                   action: fgAction, key: key)),
            .action(PikaMenuAction(title: PikaText.textColorBackground, flatTitle: background,
                                   action: bgAction, key: key, modifiers: [.command, .shift])),
        ]
    }

    static var entries: [PikaMenuEntry] {
        var pika: [PikaMenuEntry] = [
            .action(PikaMenuAction(title: PikaText.textMenuAbout, action: #selector(AppDelegate.openAboutWindow))),
            .action(PikaMenuAction(title: PikaText.textMenuHelp, action: #selector(AppDelegate.openHelpWindow))),
            .action(PikaMenuAction(title: PikaText.textMenuShowSplash, action: #selector(AppDelegate.openSplashWindow))),
        ]
        #if TARGET_SPARKLE
            pika.append(.action(PikaMenuAction(title: "\(PikaText.textMenuUpdates)…",
                                               action: #selector(AppDelegate.checkForUpdates))))
        #endif
        pika.append(.action(PikaMenuAction(title: PikaText.textMenuGitHubIssue,
                                           action: #selector(AppDelegate.openGitHubIssue))))
        return [
            .action(PikaMenuAction(title: "\(PikaText.textPickForeground)…",
                                   action: #selector(AppDelegate.triggerPickForeground), key: "d")),
            .action(PikaMenuAction(title: "\(PikaText.textPickBackground)…",
                                   action: #selector(AppDelegate.triggerPickBackground), key: "d",
                                   modifiers: [.command, .shift])),
            .group(PikaText.textColorCopy, pair(
                flat: PikaText.textCopyForeground, PikaText.textCopyBackground,
                action: #selector(AppDelegate.triggerCopyForeground), #selector(AppDelegate.triggerCopyBackground),
                key: "c"
            ) + [
                .divider,
                .action(PikaMenuAction(title: PikaText.textMenuCopyAllAsText, action: #selector(AppDelegate.triggerCopyText))),
                .action(PikaMenuAction(title: PikaText.textMenuCopyAllAsJSON, action: #selector(AppDelegate.triggerCopyData))),
            ]),
            .group(PikaText.textColorPaste, pair(
                flat: PikaText.textPasteForeground, PikaText.textPasteBackground,
                action: #selector(AppDelegate.triggerPasteForeground), #selector(AppDelegate.triggerPasteBackground),
                key: "v"
            )),
            .group(PikaText.textColorSystemPicker, pair(
                flat: PikaText.textColorSystemPickerForeground, PikaText.textColorSystemPickerBackground,
                action: #selector(AppDelegate.triggerSystemPickerForeground),
                #selector(AppDelegate.triggerSystemPickerBackground),
                key: "s"
            )),
            .divider,
            .action(PikaMenuAction(title: PikaText.textColorSwapDetail, action: #selector(AppDelegate.triggerSwap),
                                   key: "x", modifiers: [])),
            .action(PikaMenuAction(title: PikaText.textColorUndo, action: #selector(AppDelegate.triggerUndo),
                                   key: "z", windowOnly: true)),
            .action(PikaMenuAction(title: PikaText.textColorRedo, action: #selector(AppDelegate.triggerRedo),
                                   key: "z", modifiers: [.command, .shift], windowOnly: true)),
            .divider,
            .palettes,
            .group("Pika", pika),
            .action(PikaMenuAction(title: "\(PikaText.textMenuPreferences)…",
                                   action: #selector(AppDelegate.openPreferencesWindow), key: ",")),
            .divider,
            .action(PikaMenuAction(title: PikaText.textMenuQuit, action: #selector(AppDelegate.terminatePika), key: "q")),
        ]
    }

    /// The right-click menu: `entries` without the window's own items, with each group laid out
    /// flat between dividers, and its shortcuts shown.
    static func statusMenu(delegate: NSMenuDelegate) -> NSMenu {
        let menu = NSMenu(title: "Status Bar Menu")
        menu.delegate = delegate
        func addDivider() {
            if let last = menu.items.last, !last.isSeparatorItem { menu.addItem(.separator()) }
        }
        func add(_ entries: [PikaMenuEntry], flat: Bool) {
            for entry in entries {
                switch entry {
                case let .action(action) where !action.windowOnly:
                    let item = NSMenuItem(title: flat ? action.flatTitle ?? action.title : action.title,
                                          action: action.action, keyEquivalent: action.key)
                    item.keyEquivalentModifierMask = action.modifiers
                    menu.addItem(item)
                case let .group(_, children):
                    addDivider()
                    add(children.filter { if case .divider = $0 { return false } else { return true } }, flat: true)
                    addDivider()
                case .divider:
                    addDivider()
                case .action, .palettes:
                    break
                }
            }
        }
        add(entries, flat: false)
        if menu.items.last?.isSeparatorItem == true { menu.removeItem(at: menu.items.count - 1) }
        return menu
    }
}

/// The toolbar's More menu: `PikaMenu.entries`, with groups as submenus and shortcuts shown.
struct NavigationMenuItems: View {
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Default(.historyDrawerVisible) var historyDrawerVisible

    private var exportLabel: String {
        guard historyDrawerVisible else { return PikaText.textHistoryExport }
        let idx = activePaletteIndex
        if idx > 0, idx < palettes.count, palettes[idx].name != nil {
            return PikaText.textPaletteExport
        }
        return PikaText.textHistoryExport
    }

    var body: some View {
        entries(PikaMenu.entries)
    }

    private func entries(_ entries: [PikaMenuEntry]) -> some View {
        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
            entryView(entry)
        }
    }

    @ViewBuilder private func entryView(_ entry: PikaMenuEntry) -> some View {
        switch entry {
        case let .action(action):
            actionButton(action)
        case let .group(title, children):
            MenuGroup(title: title) { AnyView(entries(children)) }
        case .divider:
            Divider()
        case .palettes:
            MenuGroup(title: PikaText.textViewPalettes) {
                Button(PikaText.textPaletteNew) { NotificationCenter.default.post(name: .savePalette, object: nil) }
                Button(exportLabel) { NotificationCenter.default.post(name: .exportPalette, object: nil) }
            }
        }
    }

    @ViewBuilder private func actionButton(_ action: PikaMenuAction) -> some View {
        let button = Button(action.title) { NSApp.sendAction(action.action, to: nil, from: nil) }
        if let character = action.key.first {
            button.keyboardShortcut(KeyEquivalent(character), modifiers: Self.modifiers(action.modifiers))
        } else {
            button
        }
    }

    private static func modifiers(_ flags: NSEvent.ModifierFlags) -> EventModifiers {
        var modifiers: EventModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        return modifiers
    }
}

struct NavigationItems_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenuItems()
    }
}
