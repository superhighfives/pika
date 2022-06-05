import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.hideColorNames) var hideColorNames
    @Default(.betaUpdates) var betaUpdates
    @Default(.combineCompliance) var combineCompliance
    @Default(.hidePikaWhilePicking) var hidePikaWhilePicking
    @Default(.copyColorOnPick) var copyColorOnPick
    @Default(.copyFormat) var copyFormat
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]

    @EnvironmentObject var eyedroppers: Eyedroppers
    @EnvironmentObject var windowManager: WindowManager

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

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text(PikaText.textGeneralTitle).font(.system(size: 16))
                        LaunchAtLogin.Toggle {
                            Text(PikaText.textLaunchDescription)
                        }
                        Toggle(isOn: $hideMenuBarIcon) {
                            Text(PikaText.textIconDescription)
                        }
                        Toggle(isOn: $betaUpdates) {
                            Text(PikaText.textBetaDescription)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.all, 24.0)

                    Divider()

                    VStack(alignment: .leading, spacing: 10.0) {
                        Text(PikaText.textSelectionTitle).font(.system(size: 16))
                        Toggle(isOn: $hidePikaWhilePicking) {
                            Text(PikaText.textPickHide)
                        }
                        Toggle(isOn: $hideColorNames) {
                            Text(PikaText.textColorNamesDescription)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.all, 24.0)
                }
                .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .padding(.bottom, 16.0)

                VStack(alignment: .leading, spacing: 10.0) {
                    Text(PikaText.textAppearanceTitle).font(.system(size: 16))

                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let horizontalUnit = width / 2

                        HStack(spacing: 20.0) {
                            let colorWCAGCompliance = eyedroppers.foreground.color.toWCAGCompliance(
                                with: eyedroppers.background.color
                            )
                            Button(action: {
                                combineCompliance = false
                            }, label: {
                                ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance, theme: .weight)
                                    .padding(20.0)
                                    .frame(maxWidth: horizontalUnit - 10, maxHeight: .infinity, alignment: .leading)
                            })
                                .buttonStyle(AppearanceButtonStyle(
                                    title: PikaText.textAppearanceWeightTitle,
                                    description: PikaText.textAppearanceWeightDescription,
                                    selected: combineCompliance == false
                                ))

                            Button(action: {
                                combineCompliance = true
                            }, label: {
                                ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance, theme: .contrast)
                                    .padding(20.0)
                                    .frame(maxWidth: horizontalUnit - 10, maxHeight: .infinity, alignment: .leading)
                            })
                                .buttonStyle(AppearanceButtonStyle(
                                    title: PikaText.textAppearanceContrastTitle,
                                    description: PikaText.textAppearanceContrastDescription,
                                    selected: combineCompliance == true
                                ))
                        }
                        .frame(maxWidth: width)
                    }
                    .frame(height: 120)
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 16.0)

                // Copy Settings
                VStack(alignment: .leading, spacing: 16.0) {
                    Text(PikaText.textCopyTitle).font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 12.0) {
                        HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                            Text(PikaText.textCopyExport)
                                .fixedSize()
                            Picker(PikaText.textCopyFormat, selection: $copyFormat) {
                                ForEach(CopyFormat.allCases, id: \.self) { value in
                                    Text(value.localizedString())
                                }
                            }
                            .pickerStyle(RadioGroupPickerStyle())
                            .horizontalRadioGroupLayout()
                            .fixedSize()
                            .labelsHidden()
                        }

                        ColorExampleRow(copyFormat: copyFormat, eyedropper: eyedroppers.foreground)
                    }

                    Toggle(isOn: $copyColorOnPick) {
                        Text(PikaText.textCopyAutomatic)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 16.0)

                // Color Format

                VStack(alignment: .leading, spacing: 8.0) {
                    Section(header: Text(PikaText.textFormatTitle).font(.system(size: 16))) {
                        VStack(alignment: .leading, spacing: 12.0) {
                            Section(header:
                                Text(PikaText.textFormatDescription).font(.system(size: 13, weight: .medium))
                            ) {
                                Picker(PikaText.textSpaceTitle, selection:
                                    $colorSpace.onChange(perform: { Defaults[.colorSpace] = $0 })) {
                                    ForEach(primarySpaces, id: \.self) { value in
                                        if value == systemDefaultSpace {
                                            Text("\(PikaText.textSystemDefault) (\(value.localizedName!))")
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

                VStack(alignment: .leading, spacing: 8.0) {
                    Section(header: Text(PikaText.textHotkeyTitle).font(.system(size: 16))) {
                        VStack(alignment: .leading, spacing: 12.0) {
                            Text(PikaText.textHotkeyDescription).font(.system(size: 13, weight: .medium))
                            KeyboardShortcuts.Recorder(for: .togglePika)
                        }
                    }
                    .padding(.horizontal, 24.0)
                }
                .padding(.bottom, 24.0)
            }
        }
        .padding(.bottom, -windowManager.toolbarPadding)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Eyedroppers())
            .environmentObject(WindowManager())
            .frame(width: 750, height: 700)
    }
}
