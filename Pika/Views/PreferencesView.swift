import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

// MARK: - Sub-views

private struct GeneralAndSelectionSection: View {
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.hideColorNames) var hideColorNames
    #if TARGET_SPARKLE
        @Default(.betaUpdates) var betaUpdates
    #endif
    @Default(.hidePikaWhilePicking) var hidePikaWhilePicking
    @Default(.appMode) var appMode
    @Default(.appFloating) var appFloating
    @Default(.alwaysShowOnLaunch) var alwaysShowOnLaunch
    @Default(.showColorOverlay) var showColorOverlay
    @Default(.colorOverlayDuration) var colorOverlayDuration
    @State var disableHideMenuBarIcon = true

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 10.0) {
                Text(PikaText.textGeneralTitle).font(.system(size: 16))
                LaunchAtLogin.Toggle {
                    Text(PikaText.textLaunchDescription)
                }
                #if TARGET_SPARKLE
                    Toggle(isOn: $betaUpdates) {
                        Text(PikaText.textBetaDescription)
                    }
                #endif
                Toggle(isOn: $alwaysShowOnLaunch) {
                    Text(PikaText.textAlwaysShowOnLaunch)
                }
                #if TARGET_SPARKLE
                .onReceive([betaUpdates].publisher.first()) { _ in
                        NSApp.sendAction(
                            #selector(AppDelegate.updateFeedURL),
                            to: nil, from: nil
                        )
                    }
                #endif
                if appMode != .menubar {
                    Toggle(isOn: $disableHideMenuBarIcon) {
                        Text(PikaText.textIconDescription)
                    }.disabled(true)
                } else {
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
                Toggle(isOn: $showColorOverlay) {
                    Text(PikaText.textShowColorOverlay)
                }
                if showColorOverlay {
                    HStack(spacing: 8.0) {
                        Text(PikaText.textDuration)
                            .font(.system(size: 12))
                        Slider(value: $colorOverlayDuration, in: 1.0 ... 5.0, step: 0.5)
                        Text(String(format: "%.1fs", colorOverlayDuration))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 20.0)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.all, 24.0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AppModeSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(PikaText.textAppTitle).font(.system(size: 16))
            HStack(spacing: 16.0) {
                AppModeButtons()
            }
            .frame(height: 96)
        }
        .padding(.horizontal, 24.0)
    }
}

private struct AppearanceSection: View {
    @Default(.contrastStandard) var contrastStandard
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(PikaText.textAppearanceTitle).font(.system(size: 16))
            HStack(spacing: 16.0) {
                Picker(PikaText.textContrastStandard, selection: $contrastStandard) {
                    ForEach(ContrastStandard.allCases, id: \.self) { value in
                        Text(value.rawValue)
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .horizontalRadioGroupLayout()
                .fixedSize()
            }
            .padding(.bottom, 8.0)
            if contrastStandard == .wcag {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    HStack(spacing: 16.0) {
                        CompliancePreviewWCAG(
                            width: width / 2 - 8,
                            foreground: eyedroppers.foreground,
                            background: eyedroppers.background
                        )
                    }
                    .frame(maxWidth: width)
                }
                .frame(height: 100)
            } else {
                GeometryReader { geometry in
                    CompliancePreviewAPCA(
                        foreground: eyedroppers.foreground,
                        background: eyedroppers.background
                    )
                    .frame(maxWidth: geometry.size.width)
                }
                .frame(height: 100)
            }
        }
        .padding(.horizontal, 24.0)
    }
}

private struct CopySettingsSection: View {
    @Default(.copyFormat) var copyFormat
    @Default(.copyColorOnPick) var copyColorOnPick
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(PikaText.textCopyTitle).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 12.0) {
                VStack(alignment: .leading, spacing: 12.0) {
                    Picker(PikaText.textCopyExport, selection: $copyFormat) {
                        ForEach(CopyFormat.allCases, id: \.self) { value in
                            Text(value.localizedString())
                        }
                        Divider()
                    }
                    .pickerStyle(.menu)
                }
                ColorExampleRow(copyFormat: copyFormat, eyedropper: eyedroppers.foreground)
            }
            Toggle(isOn: $copyColorOnPick) {
                Text(PikaText.textCopyAutomatic)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24.0)
    }
}

private struct ColorFormatSection: View {
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]

    private struct ColorSpaceConfig {
        let systemDefault: NSColorSpace
        let primary: [NSColorSpace]
        let additional: [NSColorSpace]
    }

    private func getColorSpaces() -> ColorSpaceConfig {
        let systemDefaultSpace: NSColorSpace = NSScreen.main!.colorSpace!
        var availableSpaces = NSColorSpace.availableColorSpaces(with: .rgb).unique()
        if !availableSpaces.contains(systemDefaultSpace) {
            availableSpaces.append(systemDefaultSpace)
        }
        var primarySpaces: [NSColorSpace] = []
        for space in availableSpaces {
            if space == NSColorSpace.sRGB || space == NSColorSpace.adobeRGB1998
                || space == NSColorSpace.displayP3 || space == systemDefaultSpace
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
        return ColorSpaceConfig(systemDefault: systemDefaultSpace, primary: primarySpaces, additional: availableSpaces)
    }

    var body: some View {
        let spaces = getColorSpaces()
        let primarySpaces = spaces.primary
        let availableSpaces = spaces.additional
        let systemDefaultSpace = spaces.systemDefault

        VStack(alignment: .leading, spacing: 8.0) {
            Text(PikaText.textFormatTitle).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 12.0) {
                Picker(
                    PikaText.textFormatDescription,
                    selection: $colorSpace.onChange(perform: {
                        NSColorPanel.shared.close()
                        Defaults[.colorSpace] = $0
                    })
                ) {
                    ForEach(primarySpaces, id: \.self) { value in
                        if value == systemDefaultSpace {
                            Text("\(PikaText.textSystemDefault) (\(value.localizedName!))").tag(value)
                        } else {
                            Text(value.localizedName!).tag(value)
                        }
                    }
                    Divider()
                    ForEach(availableSpaces, id: \.self) { value in
                        Text(value.localizedName!).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.horizontal, 24.0)
    }
}

private struct GlobalShortcutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Section(header: Text(PikaText.textHotkeyTitle).font(.system(size: 16))) {
                HStack(spacing: 12.0) {
                    Text(PikaText.textHotkeyDescription).font(.system(size: 13, weight: .medium))
                    KeyboardShortcuts.Recorder(for: .togglePika)
                }
            }
            .padding(.horizontal, 24.0)
        }
    }
}

// MARK: - Version Info

private struct PreferencesVersionInfo: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            let textVersion = PikaText.textAboutVersion
            let textBuild = PikaText.textAboutBuild
            let textUnknown = PikaText.textAboutUnknown
            Text("\(textVersion) \(appVersion ?? textUnknown)")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 1)
            Text("(\(textBuild) \(buildNumber ?? textUnknown))")
                .foregroundColor(.white.opacity(0.5))
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 1)
        }
    }
}

// MARK: - Main View

struct PreferencesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Header

                VisualisationHeader(height: 180) {
                    PreferencesVersionInfo()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                .background(
                    GeometryReader { geo in
                        Color(red: 0.4, green: 0.0, blue: 0.7)
                            .frame(height: geo.size.height + 500)
                            .offset(y: -500)
                    }
                )
                Divider()

                // MARK: Content

                VStack(alignment: .leading, spacing: 0) {
                    GeneralAndSelectionSection()

                    Divider().padding(.bottom, 16.0)

                    AppModeSection()

                    Divider().padding(.vertical, 16.0)

                    AppearanceSection()

                    Divider().padding(.vertical, 16.0)

                    CopySettingsSection()

                    Divider().padding(.vertical, 16.0)

                    ColorFormatSection()

                    Divider().padding(.vertical, 16.0)

                    GlobalShortcutSection()
                }
                .padding(.bottom, 24.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(Eyedroppers())
            .frame(width: 580, height: 600)
    }
}
