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
        HStack(spacing: 4.0) {
            Picker(PikaText.textFormatTitle, selection: $colorFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .selectionDisabled(isFormatDisabled(value))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()
            .frame(width: 100.0)

            ColorSpaceMenu()
                .padding(.trailing, 4.0)

            Button(action: {
                NSApp.sendAction(#selector(AppDelegate.triggerToggleColorPreview), to: nil, from: nil)
            }, label: {
                IconImage(name: showColorPreview ? "eye" : "eye.slash")
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 6.0)
            .foregroundStyle(showColorPreview ? Color.accentColor : Color.primary)
            .help("\(PikaText.textColorPreviewToggle) (P)")

            Button(action: {
                NSApp.sendAction(#selector(AppDelegate.triggerToggleCompliance), to: nil, from: nil)
            }, label: {
                IconImage(name: showCompliance ? "checkmark.shield.fill" : "checkmark.shield")
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 6.0)
            .foregroundStyle(showCompliance ? Color.accentColor : Color.primary)
            .help("\(PikaText.textComplianceToggle) (C)")

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    historyDrawerVisible.toggle()
                }
            }, label: {
                IconImage(name: historyDrawerVisible ? "clock.arrow.circlepath" : "clock")
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 6.0)
            .foregroundStyle(historyDrawerVisible ? Color.accentColor : Color.primary)
            .help("\(PikaText.textHistoryToggle) (H)")

            Menu {
                NavigationMenuItems()
            } label: {
                IconImage(name: "gearshape")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .menuIndicator(.visible)
            .frame(alignment: .leading)
            .padding(.leading, 6.0)
            .padding(.trailing, 10.0)
            .fixedSize()
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

    var body: some View {
        Menu {
            Picker(PikaText.textSpaceTitle, selection: Binding(
                get: { option },
                set: { ColorSpacePreference.select($0) }
            )) {
                // A space chosen in Settings outside the three main ones stays listed.
                ColorSpaceOptions(otherSpaces: {
                    if case let .space(space) = option, !ColorSpacePreference.isCommon(space) { return [space] }
                    return []
                }())
            }
            .pickerStyle(.inline)
            .labelsHidden()
            Divider()
            Button(PikaText.textSpaceMismatch) {
                NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
            }
            Button(PikaText.textSpaceLearn) {
                NSWorkspace.shared.open(URL(string: PikaConstants.colorSpaceHelpURL)!)
            }
        } label: {
            Text(label)
        }
        .fixedSize()
        .help(PikaText.textSpaceTitle)
        .accessibilityLabel(PikaText.textSpaceTitle)
        // Settings, Check a Color and Match display following the screen change it too.
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let current = ColorSpacePreference.current
            if current != option { option = current }
        }
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
