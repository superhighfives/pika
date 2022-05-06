import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.hideColorNames) var hideColorNames
    @Default(.betaUpdates) var betaUpdates
    @Default(.hidePikaWhilePicking) var hidePikaWhilePicking
    @Default(.copyColorOnPick) var copyColorOnPick
    @Default(.copyFormat) var copyFormat
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]

    // swiftlint:disable large_tuple opening_brace
    func getColorSpaces() -> ([NSColorSpace], [NSColorSpace], NSColorSpace) {
        let systemDefaultSpace: NSColorSpace = NSScreen.main!.colorSpace!
        var availableSpaces = NSColorSpace.availableColorSpaces(with: .rgb).unique()
        if !availableSpaces.contains(systemDefaultSpace) {
            availableSpaces.append(systemDefaultSpace)
        }
        var primarySpaces: [NSColorSpace] = []

        for space in availableSpaces {
            if space == NSColorSpace.sRGB ||
                space == NSColorSpace.adobeRGB1998 ||
                space == NSColorSpace.displayP3 ||
                space == systemDefaultSpace
            {
                guard let index = availableSpaces.firstIndex(of: space) else { continue }
                availableSpaces.remove(at: index)

                if space == systemDefaultSpace {
                    primarySpaces.insert(space, at: 0)
                } else {
                    primarySpaces.append(space)
                }
            }
        }

        return (primarySpaces, availableSpaces, systemDefaultSpace)
    }

    // swiftlint:enable large_tuple opening_brace

    var body: some View {
        let (primarySpaces, availableSpaces, systemDefaultSpace) = self.getColorSpaces()

        HStack(alignment: .top, spacing: 0) {
            Group {
                AppVersion()
            }
            .frame(maxWidth: 240.0, maxHeight: .infinity)
            .background(VisualEffect(
                material: NSVisualEffectView.Material.sidebar,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            ))

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                // General Settings
                let textGeneralTitle = NSLocalizedString("preferences.general.title", comment: "General Settings")
                let textLaunchDescription = NSLocalizedString(
                    "preferences.launch.description",
                    comment: "Launch at login"
                )
                let textIconDescription = NSLocalizedString(
                    "preferences.icon.description",
                    comment: "Hide menu bar icon"
                )
                let textBetaDescription = NSLocalizedString(
                    "preferences.beta.description",
                    comment: "Subscribe to beta releases"
                )

                let textSelectionTitle = NSLocalizedString("preferences.selection.title", comment: "Selection Settings")
                let textPickHide = NSLocalizedString("preferences.pick.hide", comment: "Hide Pika while picking")
                let textColorNamesDescription = NSLocalizedString(
                    "preferences.names.description",
                    comment: "Hide color names"
                )

                let textCopyTitle = NSLocalizedString("preferences.copy.title", comment: "Copy Settings")
                let textCopyExport = NSLocalizedString("preferences.copy.export", comment: "Export color for")
                let textCopyFormat = NSLocalizedString("preferences.copy.format", comment: "Export Format")
                let textCopyAutomatic = NSLocalizedString("preferences.copy.automatic", comment: "Automatically copy color to clipboard on pick")

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text(textGeneralTitle).font(.system(size: 16))
                        LaunchAtLogin.Toggle {
                            Text(textLaunchDescription)
                        }
                        Toggle(isOn: $hideMenuBarIcon) {
                            Text(textIconDescription)
                        }
                        Toggle(isOn: $betaUpdates) {
                            Text(textBetaDescription)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.all, 24.0)

                    Divider()

                    VStack(alignment: .leading, spacing: 10.0) {
                        Text(textSelectionTitle).font(.system(size: 16))
                        Toggle(isOn: $hidePikaWhilePicking) {
                            Text(textPickHide)
                        }
                        Toggle(isOn: $hideColorNames) {
                            Text(textColorNamesDescription)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.all, 24.0)
                }
                .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .padding(.bottom, 16.0)

                VStack(alignment: .leading, spacing: 8.0) {
                    Text(textCopyTitle).font(.system(size: 16))
                    HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                        Text(textCopyExport)
                            .fixedSize()
                        Picker(textCopyFormat, selection: $copyFormat) {
                            ForEach(CopyFormat.allCases, id: \.self) { value in
                                Text(value.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .fixedSize()
                        .labelsHidden()
                    }

                    Toggle(isOn: $copyColorOnPick) {
                        Text(textCopyAutomatic)
                    }
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 16.0)

                // Color Format
                let textFormatTitle = NSLocalizedString("preferences.format.title", comment: "Color Format")
                let textFormatDescription = NSLocalizedString(
                    "preferences.space.description",
                    comment: "Set your RGB color space"
                )
                let textSpaceTitle = NSLocalizedString("preferences.space.title", comment: "Color Space")
                let textSystemDefault = NSLocalizedString("preferences.space.default", comment: "System Default")

                VStack(alignment: .leading, spacing: 8.0) {
                    Section(header: Text(textFormatTitle).font(.system(size: 16))) {
                        VStack(alignment: .leading, spacing: 12.0) {
                            Section(header: Text(textFormatDescription).font(.system(size: 13, weight: .medium))) {
                                Picker(textSpaceTitle, selection:
                                    $colorSpace.onChange(perform: { Defaults[.colorSpace] = $0 })) {
                                    ForEach(primarySpaces, id: \.self) { value in
                                        if value == systemDefaultSpace {
                                            Text("\(textSystemDefault) (\(value.localizedName!))")
                                                .tag(value)
                                        } else {
                                            Text(value.localizedName!)
                                                .tag(value)
                                        }
                                    }
                                    Divider()
                                    ForEach(availableSpaces, id: \.self) { value in
                                        Text(value.localizedName!)
                                            .tag(value)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                    .padding(.horizontal, 24.0)
                }

                Divider()
                    .padding(.vertical, 16.0)

                // Global Shortcut
                let textHotkeyTitle = NSLocalizedString("preferences.hotkey.title", comment: "Global Shortcut")
                let textHotkeyDescription = NSLocalizedString(
                    "preferences.hotkey.description",
                    comment: "Set a global hotkey shortcut to invoke Pika"
                )

                VStack(alignment: .leading, spacing: 8.0) {
                    Section(header: Text(textHotkeyTitle).font(.system(size: 16))) {
                        VStack(alignment: .leading, spacing: 12.0) {
                            Text(textHotkeyDescription).font(.system(size: 13, weight: .medium))
                            KeyboardShortcuts.Recorder(for: .togglePika)
                        }
                    }
                    .padding(.horizontal, 24.0)
                }
            }
            .padding(.bottom, 24.0)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .frame(width: 720, height: 500)
    }
}
