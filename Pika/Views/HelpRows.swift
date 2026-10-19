import SwiftUI

// MARK: - Description Row

struct HelpDescriptionRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }
}

// MARK: - Basics Grid

struct HelpBasicsGrid: View {
    let entries: [HelpBasic]

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(Array(stride(from: 0, to: entries.count, by: 2)), id: \.self) { index in
                GridRow {
                    HelpBasicCard(entry: entries[index])
                    if index + 1 < entries.count {
                        HelpBasicCard(entry: entries[index + 1])
                    } else {
                        Color.clear
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct HelpBasicCard: View {
    let entry: HelpBasic

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        let tint = colorScheme == .light ? entry.tint.light : entry.tint.dark
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(tint)
            HelpKeycapText(text: entry.text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .light ? Color.black.opacity(0.04) : Color.white.opacity(0.05))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Keycap Text

/// Text where `[⌘S]`-style runs are drawn inline as key caps, one cap per character,
/// matching the caps in the shortcut rows. Brackets are markup in the localised strings.
struct HelpKeycapText: View {
    let text: String
    var keySize: CGFloat = 10

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.displayScale) var displayScale: CGFloat

    var body: some View {
        var result = Text(verbatim: "")
        var remaining = text[...]
        while let open = remaining.firstIndex(of: "["),
              let close = remaining[open...].firstIndex(of: "]")
        {
            result = result + Text(verbatim: String(remaining[..<open]))
            let keys = remaining[remaining.index(after: open) ..< close]
            for (index, key) in keys.enumerated() {
                if index > 0 { result = result + Text(verbatim: "\u{2009}") }
                result = result + keycap(String(key))
            }
            remaining = remaining[remaining.index(after: close)...]
        }
        return result + Text(verbatim: String(remaining))
    }

    private func keycap(_ key: String) -> Text {
        let cap = Text(verbatim: key)
            .font(.system(size: keySize, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(minWidth: keySize + 2)
            .padding(.horizontal, 4)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Color.gray.opacity(0.5), lineWidth: 1))
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: cap)
        renderer.scale = displayScale
        guard let image = renderer.nsImage else { return Text(verbatim: key) }
        return Text(Image(nsImage: image)).baselineOffset(-2)
    }
}

// MARK: - Read More Button

/// A small outlined pill that expands collapsed Help copy.
struct HelpReadMoreButton: View {
    let expanded: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(expanded ? PikaText.textHelpBasicsIntroLess : PikaText.textHelpBasicsIntroMore)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .offset(y: isHovered ? (expanded ? -1.5 : 1.5) : 0)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isHovered ? .primary : .secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.primary.opacity(isHovered ? 0.06 : 0)))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(isHovered ? 0.35 : 0.2), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Header

struct HelpSectionHeader: View {
    let title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
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

struct ShortcutEntry {
    let title: String
    let keys: [String]
    let notificationName: Notification.Name?
}

struct HelpShortcutRow: View {
    let entry: ShortcutEntry

    @State private var highlight: Bool = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Text(entry.title)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
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
            if let parsed = URL(string: url) {
                NSWorkspace.shared.open(parsed)
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                Spacer()
                Text(shorthand)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isHovered ? Color.accentColor : Color.secondary)
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

struct URLTriggerRow: View {
    let url: String
    let description: String

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Button {
            if let parsed = URL(string: url) {
                NSWorkspace.shared.open(parsed)
            }
        } label: {
            HStack {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                Spacer()
                Text(url)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isHovered ? Color.accentColor : Color.secondary)
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

struct FormatRow: View {
    let name: String
    let example: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
            Text(example)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
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
