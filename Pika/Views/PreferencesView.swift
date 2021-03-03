import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @Default(.colorFormat) var colorFormat
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.betaUpdates) var betaUpdates
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]

    // swiftlint:disable large_tuple opening_brace
    func getColorSpaces() -> ([NSColorSpace], [NSColorSpace], NSColorSpace) {
        let systemDefaultSpace: NSColorSpace = NSScreen.main!.colorSpace!
        var availableSpaces = NSColorSpace.availableColorSpaces(with: .rgb).unique()
        availableSpaces.append(systemDefaultSpace)
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

        HStack(spacing: 0) {
            Group {
                AppVersion()
            }
            .frame(maxWidth: 180.0, maxHeight: .infinity)
            .background(VisualEffect(
                material: NSVisualEffectView.Material.sidebar,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            ))

            Divider()

            VStack(alignment: .leading, spacing: 10.0) {
                // Color Format
                let textFormatTitle = NSLocalizedString("preferences.format.title", comment: "Color Format")
                let textFormatDescription = NSLocalizedString(
                    "preferences.format.description",
                    comment: "Set your preferred display format for colors"
                )

                let textSpaceTitle = NSLocalizedString("preferences.space.title", comment: "Color Space")
                let textSpaceDescription = NSLocalizedString(
                    "preferences.space.description",
                    comment: "Set your RGB color space"
                )

                Section(header: Text(textFormatTitle).font(.system(size: 16))) {
                    VStack(alignment: .leading, spacing: 15.0) {
                        Text(textFormatDescription)
                        Picker(textFormatTitle, selection: $colorFormat) {
                            ForEach(ColorFormat.allCases, id: \.self) { value in
                                Text(value.rawValue)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .horizontalRadioGroupLayout()
                        .labelsHidden()
                    }

                    Spacer()
                        .frame(height: 0.0)

                    VStack(alignment: .leading, spacing: 15.0) {
                        Text(textSpaceDescription)
                        Picker(textSpaceTitle, selection:
                            $colorSpace.onChange(perform: { Defaults[.colorSpace] = $0 })) {
                            ForEach(primarySpaces, id: \.self) { value in
                                if value === systemDefaultSpace {
                                    Text("System Default (\(value.localizedName!))")
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
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 10.0)

                // Global Shortcut
                let textHotkeyTitle = NSLocalizedString("preferences.hotkey.title", comment: "Global Shortcut")
                let textHotkeyDescription = NSLocalizedString(
                    "preferences.hotkey.description",
                    comment: "Set a global hotkey shortcut to invoke Pika"
                )

                Section(header: Text(textHotkeyTitle).font(.system(size: 16))) {
                    VStack(alignment: .leading, spacing: 15.0) {
                        Text(textHotkeyDescription)
                        KeyboardShortcuts.Recorder(for: .togglePika)
                    }
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 10.0)

                // Launch at login
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

                Section(header: Text(textGeneralTitle).font(.system(size: 16))) {
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
                .padding(.horizontal, 24.0)
            }
            .padding(.all, 0.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
