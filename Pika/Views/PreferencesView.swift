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
    @Default(.appMode) var appMode
    @Default(.appFloating) var appFloating
    @Default(.alwaysShowOnLaunch) var alwaysShowOnLaunch
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]
    @State private var viewHeight: CGFloat = 0.0

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
            ZStack {
                Visualisation()
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

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 10.0) {
                            Text(PikaText.textGeneralTitle).font(.system(size: 16))
                            LaunchAtLogin.Toggle {
                                Text(PikaText.textLaunchDescription)
                            }
                            Toggle(isOn: $betaUpdates) {
                                Text(PikaText.textBetaDescription)
                            }
                            Toggle(isOn: $alwaysShowOnLaunch) {
                                Text(PikaText.textAlwaysShowOnLaunch)
                            }
                            .onReceive([self.betaUpdates].publisher.first()) { _ in
                                NSApp.sendAction(#selector(AppDelegate.updateFeedURL), to: nil, from: nil)
                            }
                            if appMode == .menubar {
                                Toggle(isOn: $hideMenuBarIcon) {
                                    Text(PikaText.textIconDescription)
                                }
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
                            Toggle(isOn: $appFloating) {
                                Text(PikaText.textFloatDescription)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.all, 24.0)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .padding(.bottom, 16.0)

                    VStack(alignment: .leading, spacing: 10.0) {
                        Text(PikaText.textAppTitle).font(.system(size: 16))

                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let horizontalUnit = width / 2

                            HStack(spacing: 16.0) {
                                AppModeButtons(
                                    width: horizontalUnit - 8
                                )
                            }
                            .frame(maxWidth: width)
                        }
                        .frame(height: 96)
                    }
                    .padding(.horizontal, 24.0)
                }

                Divider()
                    .padding(.vertical, 16.0)

                VStack(alignment: .leading, spacing: 10.0) {
                    Text(PikaText.textAppearanceTitle).font(.system(size: 16))

                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let horizontalUnit = width / 2

                        HStack(spacing: 16.0) {
                            ComplianceButtons(
                                width: horizontalUnit - 8,
                                foreground: eyedroppers.foreground,
                                background: eyedroppers.background
                            )
                        }
                        .frame(maxWidth: width)
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 16.0)

                // Copy Settings
                VStack(alignment: .leading, spacing: 10.0) {
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
            .background(
                GeometryReader { contentGeometry in
                    Color.clear.onAppear {
                        viewHeight = contentGeometry.size.height
                    }
                }
            )
            .useScrollView(when: viewHeight > windowManager.screenHeight, showsIndicators: false)
        }
        .padding(.bottom, viewHeight > windowManager.screenHeight ? 0 : -windowManager.toolbarPadding)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Eyedroppers())
            .environmentObject(WindowManager())
            .frame(width: 750, height: 850)
    }
}
