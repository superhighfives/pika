import SwiftUI

// MARK: - Description Row

private struct HelpDescriptionRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }
}

// MARK: - Section Header

private struct HelpSectionHeader: View {
    let title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 20.0)
        .padding(.vertical, 8.0)
        .background(colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.2))
    }
}

// MARK: - Shortcut Row

private struct ShortcutEntry {
    let title: String
    let keys: [String]
    let notificationName: Notification.Name?
}

private struct HelpShortcutRow: View {
    let entry: ShortcutEntry

    @State private var highlight: Bool = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Text(entry.title)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Spacer()
            HStack(spacing: 3) {
                ForEach(entry.keys, id: \.self) { key in
                    KeyboardShortcutKey { Text(key).font(.system(size: 11, weight: .semibold, design: .rounded)) }
                }
            }
        }
        .padding(.horizontal, 20.0)
        .padding(.vertical, 5.0)
        .background(highlight
            ? (colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.07))
            : Color.clear)
        .animation(.easeOut(duration: 0.4), value: highlight)
        .onReceive(NotificationCenter.default.publisher(for: entry.notificationName ?? .init("noop"))) { _ in
            guard entry.notificationName != nil else { return }
            highlight = true
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                highlight = false
            }
        }
    }
}

// MARK: - External Link Row

struct HelpExternalLinkRow: View {
    let title: String
    let url: String
    let shorthand: String
    var verticalPadding: CGFloat = 5.0

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Button {
            if let u = URL(string: url) {
                NSWorkspace.shared.open(u)
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                Spacer()
                Text(shorthand)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isHovered ? .accentColor : .secondary)
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, verticalPadding)
            .background(isHovered
                ? (colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.07))
                : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - URL Trigger Row

private struct URLTriggerRow: View {
    let url: String
    let description: String

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Button {
            if let u = URL(string: url) {
                NSWorkspace.shared.open(u)
            }
        } label: {
            HStack {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                Spacer()
                Text(url)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isHovered ? .accentColor : .secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, 5.0)
            .background(isHovered
                ? (colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.07))
                : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Format Row

private struct FormatRow: View {
    let name: String
    let example: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Text(example)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 3) {
                KeyboardShortcutKey { Text("⌘").font(.system(size: 11, weight: .semibold, design: .rounded)) }
                KeyboardShortcutKey { Text(shortcut).font(.system(size: 11, weight: .semibold, design: .rounded)) }
            }
        }
        .padding(.horizontal, 20.0)
        .padding(.vertical, 5.0)
    }
}

// MARK: - Data

private typealias ShortcutGroup = (title: String, entries: [ShortcutEntry])

private let shortcutGroups: [ShortcutGroup] = [
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

private typealias URLGroup = (title: String, entries: [(url: String, description: String)])

private let urlGroups: [URLGroup] = [
    (PikaText.textUrlGroupPick, [
        ("pika://pick/foreground", PikaText.textPickForeground),
        ("pika://pick/background", PikaText.textPickBackground),
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
    (PikaText.textUrlGroupWindow, [
        ("pika://window/about", PikaText.textUrlWindowAbout),
        ("pika://window/help", PikaText.textUrlWindowHelp),
        ("pika://window/preferences", PikaText.textUrlWindowPreferences),
        ("pika://window/resize/<w>/<h>", PikaText.textUrlWindowResize),
    ]),
    (PikaText.textUrlGroupAppearance, [
        ("pika://appearance/light", PikaText.textUrlAppearanceLight),
        ("pika://appearance/dark", PikaText.textUrlAppearanceDark),
        ("pika://appearance/system", PikaText.textUrlAppearanceSystem),
    ]),
]

private let formats: [(name: String, example: String, shortcut: String)] = [
    (PikaText.textFormatHex, "#8F0FD0", "1"),
    (PikaText.textFormatRGB, "143, 15, 208", "2"),
    (PikaText.textFormatHSB, "277°, 93%, 82%", "3"),
    (PikaText.textFormatHSL, "277°, 86%, 44%", "4"),
    (PikaText.textFormatLAB, "36, 62, −69", "5"),
    (PikaText.textFormatOpenGL, "0.56, 0.06, 0.82", "6"),
    (PikaText.textFormatOKLCH, "0.45, 0.24, 299°", "7"),
]

// MARK: - HelpView

struct HelpView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Header

                VisualisationHeader(height: 180) {
                    Text(PikaText.textMenuHelp)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                .background(
                    GeometryReader { geo in
                        Color(red: 0.4, green: 0.0, blue: 0.7)
                            .frame(height: geo.size.height + 500)
                            .offset(y: -500)
                    }
                )
                Divider()

                HelpDescriptionRow(text: PikaText.textHelpDescription)
                Divider()

                // MARK: Keyboard Shortcuts

                HelpSectionHeader(title: PikaText.textHelpKeyboardShortcuts)
                Divider()
                ForEach(shortcutGroups.indices, id: \.self) { gi in
                    let group = shortcutGroups[gi]
                    VStack(spacing: 0) {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        ForEach(group.entries.indices, id: \.self) { ei in
                            HelpShortcutRow(entry: group.entries[ei])
                            if ei < group.entries.count - 1 {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    if gi < shortcutGroups.count - 1 {
                        Divider()
                    }
                }
                Divider()

                // MARK: URL Triggers

                HelpSectionHeader(title: PikaText.textHelpURLTriggers)
                Divider()
                HelpDescriptionRow(text: PikaText.textHelpURLTriggersDescription)
                Divider()
                ForEach(urlGroups.indices, id: \.self) { gi in
                    let group = urlGroups[gi]
                    VStack(spacing: 0) {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        ForEach(group.entries.indices, id: \.self) { ei in
                            URLTriggerRow(url: group.entries[ei].url, description: group.entries[ei].description)
                            if ei < group.entries.count - 1 {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    if gi < urlGroups.count - 1 {
                        Divider()
                    }
                }
                Divider()

                // MARK: Colour Formats

                HelpSectionHeader(title: PikaText.textHelpFormats)
                Divider()
                VStack(spacing: 0) {
                    ForEach(formats.indices, id: \.self) { index in
                        FormatRow(name: formats[index].name, example: formats[index].example, shortcut: formats[index].shortcut)
                        if index < formats.count - 1 {
                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                Divider()

                // MARK: Open Source

                HelpSectionHeader(title: PikaText.textHelpOpenSource)
                Divider()
                HelpDescriptionRow(text: PikaText.textHelpOpenSourceDescription)
                Divider()
                VStack(spacing: 0) {
                    HelpExternalLinkRow(title: PikaText.textHelpViewOnGitHub, url: PikaConstants.gitHubRepoURL, shorthand: "github.com/superhighfives/pika")
                    Divider().padding(.horizontal, 20)
                    HelpExternalLinkRow(title: PikaText.textMenuGitHubIssue, url: PikaConstants.gitHubIssueURL, shorthand: "github.com/…/issues")
                    Divider().padding(.horizontal, 20)
                    HelpExternalLinkRow(title: PikaText.textHelpSupportOnMAS, url: PikaConstants.macAppStoreURL, shorthand: "apps.apple.com/…/pika")
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
            .frame(width: 550, height: 700)
    }
}
