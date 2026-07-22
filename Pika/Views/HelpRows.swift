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
