import Defaults
import SwiftUI

struct NavigationMenu: View {
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Default(.showColorPreview) var showColorPreview
    @Default(.showCompliance) var showCompliance

    func isFormatDisabled(_ format: ColorFormat) -> Bool {
        if copyFormat == .swiftUI {
            return PikaConstants.disabledFormats.contains(format)
        }
        return false
    }

    var body: some View {
        HStack(spacing: 8.0) {
            // Format and colour space as one control: the readout is "Hex in sRGB".
            HStack(spacing: 0) {
                Menu {
                    // Toggles rather than an inline picker, so each format shows its ⌘ shortcut.
                    Section(PikaText.textFormatTitle) {
                        ForEach(Array(ColorFormat.allCases.enumerated()), id: \.element) { index, value in
                            Toggle(value.rawValue, isOn: Binding(
                                get: { colorFormat == value },
                                set: { if $0 { colorFormat = value } }
                            ))
                            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                            .disabled(isFormatDisabled(value))
                        }
                    }
                } label: {
                    Text(colorFormat.rawValue).fontWeight(.semibold)
                }
                .accessibilityLabel(PikaText.textFormatTitle)
                .accessibilityValue(colorFormat.rawValue)
                .toolbarMenuSegment()
                .help(PikaText.textFormatTitle)

                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1, height: 14)

                ColorSpaceMenu()
            }
            .toolbarMenuChrome()

            ViewMenuButton()

            Menu {
                NavigationMenuItems()
            } label: {
                IconImage(name: "ellipsis")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .menuIndicator(.hidden)
            .fixedSize()
            .padding(.trailing, 8.0)
            .help(PikaText.textToolbarMore)
            .accessibilityLabel(PikaText.textToolbarMore)
        }
        .background {
            let values = ColorFormat.allCases.map { $0 }
            HStack {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Button(value.rawValue, action: {
                        if !isFormatDisabled(value) {
                            colorFormat = value
                        }
                    }).keyboardShortcut(
                        KeyEquivalent(
                            Character("\(values.firstIndex(of: value)! + 1)")
                        ), modifiers: .command
                    )
                }
                Button(PikaText.textHistoryToggle, action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        historyDrawerVisible.toggle()
                    }
                })
                .keyboardShortcut("h", modifiers: [])
                Button(PikaText.textColorPreviewToggle, action: {
                    NSApp.sendAction(#selector(AppDelegate.triggerToggleColorPreview), to: nil, from: nil)
                })
                .keyboardShortcut("p", modifiers: [])
                Button(PikaText.textComplianceToggle, action: {
                    NSApp.sendAction(#selector(AppDelegate.triggerToggleCompliance), to: nil, from: nil)
                })
                .keyboardShortcut("c", modifiers: [])
            }
            .opacity(0)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
        .onChange(of: copyFormat) {
            if copyFormat == .swiftUI {
                if PikaConstants.disabledFormats.contains(colorFormat) {
                    colorFormat = .rgb
                }
            }
        }
    }
}

/// The colour space setting, beside the format it applies to, so the space the readout and copies
/// are in is always visible. One for the whole app: a menu on each swatch read as per-swatch spaces.
private struct ColorSpaceMenu: View {
    @State private var option = ColorSpacePreference.current

    private var label: String {
        switch option {
        case .space(.sRGB): return "sRGB"
        case .space(.displayP3): return "Display P3"
        case .matchDisplay: return PikaText.textSpaceShortDisplay
        case let .space(space): return space.localizedName ?? "—"
        }
    }

    /// A checkable space, with a second line saying what it's for.
    private func spaceItem(_ value: ColorSpaceOption, title: String, subtitle: String?) -> some View {
        Toggle(isOn: Binding(
            get: { option == value },
            set: { if $0 { ColorSpacePreference.select(value) } }
        )) {
            Text(title)
            if let subtitle { Text(subtitle) }
        }
    }

    var body: some View {
        Menu {
            Section(PikaText.textSpaceTitle) {
                spaceItem(.space(.sRGB), title: "sRGB", subtitle: PikaText.textSpaceSubtitleSRGB)
                spaceItem(.space(.displayP3), title: "Display P3", subtitle: PikaText.textSpaceSubtitleP3)
                spaceItem(
                    .matchDisplay,
                    title: PikaText.textSpaceMatchDisplay,
                    subtitle: ColorSpacePreference.displaySpaceName
                )
                // A space chosen in Settings outside the three main ones stays listed.
                if case let .space(space) = option, !ColorSpacePreference.isCommon(space) {
                    spaceItem(option, title: space.localizedName ?? "—", subtitle: nil)
                }
            }
            Divider()
            Button(PikaText.textMatchTitle) {
                NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
            }
            Button(PikaText.textSpaceLearn) {
                NSWorkspace.shared.open(URL(string: PikaConstants.colorSpaceHelpURL)!)
            }
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
        .accessibilityLabel(PikaText.textSpaceTitle)
        .accessibilityValue(label)
        .toolbarMenuSegment()
        .help(PikaText.textSpaceTitle)
        // Settings, Check a Color and Match display following the screen change it too.
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let current = ColorSpacePreference.current
            if current != option { option = current }
        }
    }
}

/// The View control: the window's optional parts as checkable rows. An AppKit menu rather than a
/// SwiftUI `Menu`, so a row can stay open after a click (a macOS menu closes on any standard item,
/// but not on one drawn by a custom view) and several parts can be switched in one visit.
private struct ViewMenuButton: View {
    private struct Row {
        let title: String
        let key: String
        let setting: Defaults.Key<Bool>
        let action: Selector
    }

    private static let rows = [
        Row(title: PikaText.textViewContrast, key: "C", setting: .showCompliance,
            action: #selector(AppDelegate.triggerToggleCompliance)),
        Row(title: PikaText.textViewPalettes, key: "H", setting: .historyDrawerVisible,
            action: #selector(AppDelegate.triggerToggleHistory)),
        Row(title: PikaText.textViewPreview, key: "P", setting: .showColorPreview,
            action: #selector(AppDelegate.triggerToggleColorPreview)),
    ]

    @State private var anchor: NSView?

    var body: some View {
        Button(action: showMenu) {
            HStack(spacing: 4.0) {
                Text(PikaText.textViewMenu)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9.0, weight: .semibold))
            }
            .padding(.horizontal, 8.0)
            .frame(height: 22.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(MenuAnchor { anchor = $0 })
        .toolbarMenuChrome()
        .accessibilityLabel(PikaText.textViewMenu)
    }

    private func showMenu() {
        guard let anchor else { return }
        let menu = NSMenu()
        for row in Self.rows {
            let item = NSMenuItem()
            item.view = ToggleMenuRow(title: row.title, key: row.key, isOn: { Defaults[row.setting] }) {
                NSApp.sendAction(row.action, to: nil, from: nil)
            }
            menu.addItem(item)
        }
        // Just below the control, like the format and space menus.
        let below = anchor.isFlipped ? anchor.bounds.maxY + 4.0 : -4.0
        menu.popUp(positioning: nil, at: NSPoint(x: -4.0, y: below), in: anchor)
    }
}

/// A plain view behind a SwiftUI control, for an AppKit menu to pop up from.
private struct MenuAnchor: NSViewRepresentable {
    let onView: (NSView) -> Void

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onView(view) }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

/// A checkable menu row that toggles in place without closing its menu. Draws what a standard
/// item would: a checkmark, the title, the key on the right, and the highlight under the pointer.
private final class ToggleMenuRow: NSView {
    private let isOn: () -> Bool
    private let toggle: () -> Void
    private let check = NSImageView()
    private let titleLabel: NSTextField
    private let keyLabel: NSTextField

    init(title: String, key: String, isOn: @escaping () -> Bool, toggle: @escaping () -> Void) {
        self.isOn = isOn
        self.toggle = toggle
        titleLabel = NSTextField(labelWithString: title)
        keyLabel = NSTextField(labelWithString: key)
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        autoresizingMask = [.width]

        let font = NSFont.menuFont(ofSize: 0)
        titleLabel.font = font
        keyLabel.font = font
        keyLabel.alignment = .right
        check.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: font.pointSize - 1, weight: .semibold))

        for view in [check, titleLabel, keyLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            check.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            check.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            keyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 24),
            keyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            keyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.checkBox)
        setAccessibilityLabel(title)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var isHighlighted: Bool { enclosingMenuItem?.isHighlighted ?? false }

    /// The state just set by a click, until the setting itself is read again on the next open.
    private var shownOn: Bool?

    private func refresh() {
        let on = shownOn ?? isOn()
        check.isHidden = !on
        setAccessibilityValue(on)
        let highlighted = isHighlighted
        titleLabel.textColor = highlighted ? .selectedMenuItemTextColor : .labelColor
        keyLabel.textColor = highlighted ? .selectedMenuItemTextColor : .secondaryLabelColor
        check.contentTintColor = highlighted ? .selectedMenuItemTextColor : .labelColor
    }

    override func draw(_ dirtyRect: NSRect) {
        // The menu marks a custom item highlighted as the pointer moves over it and redraws it.
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 5, yRadius: 5).fill()
        }
        refresh()
        super.draw(dirtyRect)
    }

    override func mouseUp(with _: NSEvent) {
        flip()
    }

    override func accessibilityPerformPress() -> Bool {
        flip()
        return true
    }

    /// Toggles the setting and shows it at once. While a menu is open the app runs the menu's own
    /// event loop, which holds back queued work and SwiftUI's redraws until it closes, so a click
    /// looked like it did nothing. The check is set from the flip rather than read back, and the
    /// windows behind are laid out and drawn now.
    private func flip() {
        let wasOn = isOn()
        toggle()
        shownOn = !wasOn
        refresh()
        display()
        for window in NSApp.windows where window.isVisible && window !== self.window {
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }
    }
}

private extension View {
    /// One half of a toolbar menu control: a borderless menu with its own chevron.
    func toolbarMenuSegment() -> some View {
        menuStyle(BorderlessButtonMenuStyle())
            .menuIndicator(.visible)
            .fixedSize()
            .padding(.horizontal, 8.0)
            .frame(height: 22.0)
    }

    /// The bezel the toolbar's menus sit in, so the format/space pair reads as one control.
    func toolbarMenuChrome() -> some View {
        background(
            RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1))
                )
        )
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
