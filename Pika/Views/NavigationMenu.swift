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

            Menu {
                Toggle(PikaText.textViewContrast, isOn: Binding(
                    get: { showCompliance },
                    set: { _ in NSApp.sendAction(#selector(AppDelegate.triggerToggleCompliance), to: nil, from: nil) }
                ))
                .keyboardShortcut("c", modifiers: [])
                Toggle(PikaText.textViewPalettes, isOn: Binding(
                    get: { historyDrawerVisible },
                    set: { _ in NSApp.sendAction(#selector(AppDelegate.triggerToggleHistory), to: nil, from: nil) }
                ))
                .keyboardShortcut("h", modifiers: [])
                Toggle(PikaText.textViewPreview, isOn: Binding(
                    get: { showColorPreview },
                    set: { _ in NSApp.sendAction(#selector(AppDelegate.triggerToggleColorPreview), to: nil, from: nil) }
                ))
                .keyboardShortcut("p", modifiers: [])
            } label: {
                Text(PikaText.textViewMenu)
            }
            .toolbarMenuSegment()
            .toolbarMenuChrome()

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
