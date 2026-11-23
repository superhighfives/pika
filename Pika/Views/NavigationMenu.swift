import Defaults
import SwiftUI

struct NavigationMenu: View {
    /// The menu bar popover's View menu is a standard menu (`StandardViewMenu`).
    var standardViewMenu = false

    @ObservedObject private var toolbarSpace = ToolbarSpace.shared

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

                ColorSpaceMenu(
                    compact: !standardViewMenu && toolbarSpace.compactSpace,
                    limit: standardViewMenu ? nil : toolbarSpace.spaceLimit
                )
            }
            .toolbarMenuChrome()

            // The popover is always wide enough; the window's toolbar gives Swap up first.
            if standardViewMenu || toolbarSpace.showsSwap {
                SwapButton()
            }

            if standardViewMenu {
                StandardViewMenu()
            } else {
                ViewMenuButton()
            }

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
    /// Shortened, when the window's toolbar is short of room (`ToolbarSpace.compactSpace`).
    var compact = false
    var limit: CGFloat?

    @State private var option = ColorSpacePreference.current

    private var label: String { ToolbarSpace.spaceLabel(for: option, compact: compact, limit: limit) }

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
            Button(PikaText.textMatchMenu) {
                NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
            }
            Button(PikaText.textSpaceLearn) {
                NSWorkspace.shared.open(URL(string: PikaConstants.colorSpaceHelpURL)!)
            }
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
        .accessibilityLabel(PikaText.textSpaceTitle)
        // The full name, which the label may cut short.
        .accessibilityValue(ToolbarSpace.spaceLabel(for: option, compact: false, truncates: false))
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
    }

    private static let rows = [
        Row(title: PikaText.textViewContrast, key: "C", setting: .showCompliance),
        Row(title: PikaText.textViewPalettes, key: "H", setting: .historyDrawerVisible),
        Row(title: PikaText.textViewPreview, key: "P", setting: .showColorPreview),
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
        let rows = ToggleMenuRows()
        for row in Self.rows {
            let item = NSMenuItem()
            // Written here rather than through the toggle action: that lands in a SwiftUI
            // handler, which waits for the menu to close.
            item.view = ToggleMenuRow(title: row.title, key: row.key, rows: rows, isOn: { Defaults[row.setting] }) {
                // Palettes from here keep the window's right edge, under this menu.
                if row.setting.name == Defaults.Keys.historyDrawerVisible.name {
                    SidebarLayout.shared.keepsRightEdge = true
                }
                withAnimation(.easeInOut(duration: 0.25)) { Defaults[row.setting].toggle() }
            }
            menu.addItem(item)
        }
        // Just below the control, like the format and space menus.
        let below = anchor.isFlipped ? anchor.bounds.maxY + 4.0 : -4.0
        menu.popUp(positioning: nil, at: NSPoint(x: -4.0, y: below), in: anchor)
    }
}

/// Whether the main window's toolbar has room for Swap. Set by `PikaWindow` as the window
/// resizes: Swap is also in the ⋯ menu, so it gives way when the toolbar would otherwise run into
/// the traffic lights and the sidebar button.
final class ToolbarSpace: ObservableObject {
    static let shared = ToolbarSpace()
    @Published var showsSwap = true
    /// Short of room even without Swap, the colour space's label shortens ("Display P3" to "P3").
    @Published var compactSpace = false
    /// Still short of room, the label is cut to this width: format and space names both vary, so
    /// no one short form fits every pair at the window's narrowest.
    @Published var spaceLimit: CGFloat?

    private static let labelFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    /// The colour space's toolbar label. Any other space chosen in Settings is cut short with an
    /// ellipsis (its menu item has the full name): some, like "ACES CG Linear (Academy Color
    /// Encoding System AP1)", ran the toolbar past the window's edge.
    static func spaceLabel(
        for option: ColorSpaceOption, compact: Bool, limit: CGFloat? = nil, truncates: Bool = true
    ) -> String {
        let label: String
        switch option {
        case .space(.sRGB): label = "sRGB"
        case .space(.displayP3): label = compact ? "P3" : "Display P3"
        case .matchDisplay: label = PikaText.textSpaceShortDisplay
        case let .space(space):
            let name = space.localizedName ?? "—"
            label = truncates ? truncated(name, to: compact ? 44 : 110) : name
        }
        guard truncates, let limit else { return label }
        return truncated(label, to: limit)
    }

    /// The current space's label width, as `spaceLabel` would give it.
    static func labelWidth(compact: Bool, limit: CGFloat?) -> CGFloat {
        width(spaceLabel(for: ColorSpacePreference.current, compact: compact, limit: limit))
    }

    private static func width(_ text: String) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: labelFont]).width)
    }

    private static func truncated(_ text: String, to maxWidth: CGFloat) -> String {
        guard width(text) > maxWidth else { return text }
        var kept = text
        while !kept.isEmpty, width(kept.trimmingCharacters(in: .whitespaces) + "…") > maxWidth {
            kept.removeLast()
        }
        return kept.trimmingCharacters(in: .whitespaces) + "…"
    }
}

/// Swaps the two colours. In the toolbar, between the format and space they're read in and the
/// View menu, so it's always in the same place rather than appearing over the colours on hover.
struct SwapButton: View {
    @State private var angle: Double = 0

    var body: some View {
        Button {
            NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        } label: {
            HStack(spacing: 4.0) {
                IconImage(name: "arrow.triangle.swap")
                    .rotationEffect(.degrees(angle))
                Text(PikaText.textColorSwap)
            }
            .padding(.horizontal, 8.0)
            .frame(height: 22.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .toolbarMenuChrome()
        .help(PikaText.textColorSwap)
        .accessibilityLabel(PikaText.textColorSwap)
        // A half-turn for every swap, from here, the menus or the shortcut.
        .onReceive(NotificationCenter.default.publisher(for: .triggerSwap)) { _ in
            withAnimation(.easeInOut) { angle -= 180 }
        }
    }
}

/// The View menu in the menu bar popover: a standard menu, like the format and space menus
/// beside it, so a choice flashes and closes it. Its change lands once the menu has gone, which
/// matters for Palettes: that resizes the popover, and an open menu is placed from the popover's
/// bottom edge, so it moved.
private struct StandardViewMenu: View {
    @Default(.showCompliance) var showCompliance
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Default(.showColorPreview) var showColorPreview

    var body: some View {
        Menu {
            item(PikaText.textViewContrast, key: "c", isOn: $showCompliance)
            item(PikaText.textViewPalettes, key: "h", isOn: $historyDrawerVisible)
            item(PikaText.textViewPreview, key: "p", isOn: $showColorPreview)
        } label: {
            Text(PikaText.textViewMenu)
        }
        .accessibilityLabel(PikaText.textViewMenu)
        .toolbarMenuSegment()
        .toolbarMenuChrome()
        .help(PikaText.textViewMenu)
    }

    private func item(_ title: String, key: KeyEquivalent, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: Binding(
            get: { isOn.wrappedValue },
            set: { value in withAnimation(.easeInOut(duration: 0.25)) { isOn.wrappedValue = value } }
        ))
        .keyboardShortcut(key, modifiers: [])
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
