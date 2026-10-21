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
    @Default(.windowShadow) var windowShadow
    @Default(.pickContrastingColor) var pickContrastingColor
    @Default(.appMode) var appMode
    @Default(.appFloating) var appFloating
    @Default(.alwaysShowOnLaunch) var alwaysShowOnLaunch
    @Default(.showColorOverlay) var showColorOverlay
    @Default(.colorOverlayDuration) var colorOverlayDuration
    @Default(.pickerStyle) var pickerStyle
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
                if appMode != .menubar {
                    Toggle(isOn: $disableHideMenuBarIcon) {
                        Text(PikaText.textIconDescription)
                    }.disabled(true)
                } else {
                    Toggle(isOn: $hideMenuBarIcon) {
                        Text(PikaText.textIconDescription)
                    }
                }

                Text(PikaText.textWindowSettingsTitle)
                    .font(.system(size: 16))
                    .padding(.top, 8.0)
                Picker(PikaText.textWindowShadow, selection: $windowShadow) {
                    ForEach(WindowShadow.allCases, id: \.self) { value in
                        Text(value.localizedString())
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.all, 24.0)

            Divider()

            VStack(alignment: .leading, spacing: 10.0) {
                Text(PikaText.textSelectionTitle).font(.system(size: 16))
                Toggle(isOn: $hidePikaWhilePicking) {
                    Text(PikaText.textPickHide)
                }
                Toggle(isOn: $pickContrastingColor) {
                    Text(PikaText.textPickContrasting)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle(isOn: $hideColorNames) {
                    Text(PikaText.textColorNamesDescription)
                }
                Toggle(isOn: $appFloating) {
                    Text(PikaText.textFloatDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(appMode == .menubarPopover)
                // The custom picker shows the colour live in the loupe, so the post-pick
                // overlay (and its duration) is redundant and hidden while it's active.
                if pickerStyle != .custom {
                    Toggle(isOn: $showColorOverlay) {
                        Text(PikaText.textShowColorOverlay)
                    }
                    if showColorOverlay {
                        HStack(spacing: 8.0) {
                            Slider(value: $colorOverlayDuration, in: 1.0 ... 5.0, step: 0.5)
                                .accessibilityLabel(PikaText.textDuration)
                            Text(String(format: "%.1fs", colorOverlayDuration))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 20.0)
                    }
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

private struct PickerStyleSection: View {
    @Default(.pickerStyle) var pickerStyle
    @Default(.loupeTheme) var loupeTheme
    @State private var pendingRelaunch = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(PikaText.textPickerStyleTitle).font(.system(size: 16))

            // Same gated System/Custom comparison as the first-run splash.
            PickerChoiceView(pendingRelaunch: $pendingRelaunch)

            // The Pro loupe's style. Only relevant when the custom picker is chosen.
            if pickerStyle == .custom {
                HStack(spacing: 8.0) {
                    Text(PikaText.textLoupeTheme).font(.system(size: 13))
                    Spacer(minLength: 12.0)
                    Picker("", selection: $loupeTheme) {
                        ForEach(LoupeTheme.allCases, id: \.self) { theme in
                            Text(theme.localizedName).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }

            // Pair picking is controlled by the single "Pick a contrasting
            // background color after the foreground" toggle in the Selection
            // section — it applies to both picker styles, so it isn't duplicated
            // here per picker.
        }
        .padding(.horizontal, 24.0)
    }
}

private struct ColorNamesSection: View {
    var body: some View {
        // The picker owns its heading and description (with the refresh state on the right).
        ColorListPickerView(
            titleFont: .system(size: 16),
            subtitleFont: .system(size: 12)
        )
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
                        Text(value.localizedString())
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .horizontalRadioGroupLayout()
                .fixedSize()
            }
            .padding(.bottom, 8.0)
            Group {
                if contrastStandard == .wcag {
                    CompliancePreviewWCAG(
                        width: 258,
                        foreground: eyedroppers.foreground,
                        background: eyedroppers.background
                    )
                } else if contrastStandard == .apca {
                    CompliancePreviewAPCA(
                        foreground: eyedroppers.foreground,
                        background: eyedroppers.background
                    )
                } else {
                    CompliancePreviewBoth(
                        foreground: eyedroppers.foreground,
                        background: eyedroppers.background
                    )
                }
            }
            .frame(height: 115)
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
                    // The menu style draws the title as separate text that VoiceOver doesn't
                    // tie to the control, so name it explicitly.
                    .accessibilityLabel(PikaText.textCopyExport)
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

private struct ColorSpaceSection: View {
    @State private var option = ColorSpacePreference.current

    /// Spaces offered after the divider: everything else the system has, without the three
    /// named choices above it.
    private var otherSpaces: [NSColorSpace] {
        var spaces = NSColorSpace.availableColorSpaces(with: .rgb).unique().filter {
            !ColorSpacePreference.isCommon($0) && $0.localizedName != nil
        }
        // Keep a chosen space listed even if the system no longer offers it.
        if case let .space(space) = option, !ColorSpacePreference.isCommon(space), !spaces.contains(space) {
            spaces.append(space)
        }
        return spaces.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private var hint: String {
        switch option {
        case .space(.sRGB): return PikaText.textSpaceHintSRGB
        case .space(.displayP3): return PikaText.textSpaceHintP3
        case .matchDisplay: return PikaText.textSpaceHintDisplay
        case .space: return PikaText.textSpaceHintOther
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(PikaText.textSpaceTitle).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 8.0) {
                Picker(PikaText.textSpaceLabel, selection: $option.onChange { ColorSpacePreference.select($0) }) {
                    ColorSpaceOptions(otherSpaces: otherSpaces)
                }
                .pickerStyle(.menu)
                .fixedSize()
                .accessibilityLabel(PikaText.textSpaceLabel)
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(PikaText.textSpaceMismatch + "…") {
                    NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 24.0)
        // The readout's tag can change the space too.
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let current = ColorSpacePreference.current
            if current != option { option = current }
        }
    }
}

/// The colour space choices, shared by Preferences and the readout's tag menu.
struct ColorSpaceOptions: View {
    var otherSpaces: [NSColorSpace] = []

    var body: some View {
        Text("sRGB").tag(ColorSpaceOption.space(.sRGB))
        Text("Display P3").tag(ColorSpaceOption.space(.displayP3))
        Text(String(format: PikaText.textSpaceDisplay, ColorSpacePreference.displaySpaceName ?? "—"))
            .tag(ColorSpaceOption.matchDisplay)
        if !otherSpaces.isEmpty {
            Divider()
            ForEach(otherSpaces, id: \.self) { space in
                Text(space.localizedName ?? "").tag(ColorSpaceOption.space(space))
            }
        }
    }
}

private struct GlobalShortcutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Section(header: Text(PikaText.textHotkeyTitle).font(.system(size: 16))) {
                // Both global shortcuts the splash offers. Pick-pair was only settable during
                // onboarding, so there was no way to change ⌥⌘D afterwards.
                Grid(alignment: .leading, horizontalSpacing: 12.0, verticalSpacing: 10.0) {
                    GridRow {
                        Text(PikaText.textHotkeyDescription).font(.system(size: 13, weight: .medium))
                        KeyboardShortcuts.Recorder(for: .togglePika)
                    }
                    GridRow {
                        Text(PikaText.textPickPair).font(.system(size: 13, weight: .medium))
                        KeyboardShortcuts.Recorder(for: .pickPair)
                    }
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
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 1)
            Text("(\(textBuild) \(buildNumber ?? textUnknown))")
                .foregroundStyle(.white.opacity(0.5))
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

                    PickerStyleSection()

                    Divider().padding(.vertical, 16.0)

                    ColorNamesSection()

                    Divider().padding(.vertical, 16.0)

                    AppearanceSection()

                    Divider().padding(.vertical, 16.0)

                    CopySettingsSection()

                    Divider().padding(.vertical, 16.0)

                    ColorSpaceSection()

                    Divider().padding(.vertical, 16.0)

                    GlobalShortcutSection()
                }
                // Extra leading for labels that wrap in the narrow two-column layout (e.g. "Pick
                // contrasting color after foreground"); the default read as cramped next to the
                // spacing between rows. Single-line text is unaffected.
                .lineSpacing(3)
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
