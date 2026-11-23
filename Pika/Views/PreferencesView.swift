import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

// MARK: - General

struct GeneralSettings: View {
    @Default(.alwaysShowOnLaunch) var alwaysShowOnLaunch
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    #if TARGET_SPARKLE
        @Default(.betaUpdates) var betaUpdates
    #endif

    private var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? PikaText.textAboutUnknown
        let build = info?["CFBundleVersion"] as? String ?? PikaText.textAboutUnknown
        return "\(PikaText.textAboutVersion) \(version) (\(PikaText.textAboutBuild) \(build))"
    }

    var body: some View {
        SettingsPage {
            SettingsGroup {
                SettingsToggle(PikaText.textLaunchDescription, isOn: $launchAtLogin.isEnabled)
                SettingsDivider()
                SettingsToggle(PikaText.textAlwaysShowOnLaunch, isOn: $alwaysShowOnLaunch)
            }
            SettingsGroup(title: PikaText.textSettingsUpdates) {
                #if TARGET_SPARKLE
                    SettingsToggle(PikaText.textBetaDescription, isOn: $betaUpdates)
                    SettingsDivider()
                    SettingsRow(version) {
                        Button("\(PikaText.textMenuUpdates)…") {
                            NSApp.sendAction(#selector(AppDelegate.checkForUpdates), to: nil, from: nil)
                        }
                    }
                    .foregroundStyle(.secondary)
                #else
                    SettingsRow(version) { EmptyView() }
                        .foregroundStyle(.secondary)
                #endif
            }
        }
    }
}

// MARK: - Appearance

struct AppearanceSettings: View {
    @Default(.appMode) var appMode
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.appFloating) var appFloating
    @Default(.windowShadow) var windowShadow
    @Default(.contrastStandard) var contrastStandard
    @Default(.paletteSwatchStyle) var paletteSwatchStyle
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        SettingsPage {
            SettingsGroup(title: PikaText.textSettingsShowIn) {
                SettingsBlock {
                    HStack(spacing: 16.0) {
                        AppModeButtons()
                    }
                    .frame(height: 96)
                }
            }
            SettingsGroup {
                // The icon is how you reach Pika in menu bar mode, so it can only be hidden there.
                SettingsToggle(PikaText.textIconDescription, isOn: appMode == .menubar ? $hideMenuBarIcon : .constant(true))
                    .disabled(appMode != .menubar)
                SettingsDivider()
                SettingsToggle(PikaText.textFloatDescription, isOn: $appFloating)
                    .disabled(appMode == .menubarPopover)
                SettingsDivider()
                SettingsRow(PikaText.textWindowShadow) {
                    Picker(PikaText.textWindowShadow, selection: $windowShadow) {
                        ForEach(WindowShadow.allCases, id: \.self) { value in
                            Text(value.localizedString())
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
            }
            SettingsGroup(title: PikaText.textViewContrast) {
                SettingsRow(PikaText.textContrastStandard) {
                    Picker(PikaText.textContrastStandard, selection: $contrastStandard) {
                        ForEach(ContrastStandard.allCases, id: \.self) { value in
                            Text(value.localizedString())
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                SettingsDivider()
                SettingsBlock {
                    compliancePreview.frame(height: 115)
                }
            }
            SettingsGroup(title: PikaText.textViewPalettes) {
                SettingsRow(PikaText.textPaletteSwatches) {
                    Picker(PikaText.textPaletteSwatches, selection: $paletteSwatchStyle) {
                        ForEach(PaletteSwatchStyle.allCases, id: \.self) { value in
                            Text(value.localizedString())
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
        }
    }

    @ViewBuilder private var compliancePreview: some View {
        switch contrastStandard {
        case .wcag:
            CompliancePreviewWCAG(width: 240, foreground: eyedroppers.foreground, background: eyedroppers.background)
        case .apca:
            CompliancePreviewAPCA(foreground: eyedroppers.foreground, background: eyedroppers.background)
        case .both:
            CompliancePreviewBoth(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
    }
}

// MARK: - Picking

struct PickingSettings: View {
    @Default(.pickerStyle) var pickerStyle
    @Default(.loupeTheme) var loupeTheme
    @Default(.hidePikaWhilePicking) var hidePikaWhilePicking
    @Default(.pickContrastingColor) var pickContrastingColor
    @Default(.copyColorOnPick) var copyColorOnPick
    @Default(.showColorOverlay) var showColorOverlay
    @Default(.colorOverlayDuration) var colorOverlayDuration
    @State private var pendingRelaunch = false

    var body: some View {
        SettingsPage {
            SettingsGroup(title: PikaText.textPickerStyleTitle) {
                SettingsBlock {
                    // Same gated System/Custom comparison as the first-run splash.
                    PickerChoiceView(pendingRelaunch: $pendingRelaunch)
                }
            }
            // The Pro loupe's style, and how to change it mid-pick.
            if pickerStyle == .custom {
                SettingsGroup(footer: PikaText.textLoupeTabHint) {
                    SettingsRow(PikaText.textLoupeTheme) {
                        Picker(PikaText.textLoupeTheme, selection: $loupeTheme) {
                            ForEach(LoupeTheme.allCases, id: \.self) { theme in
                                Text(theme.localizedName).tag(theme)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
            }
            SettingsGroup {
                SettingsToggle(PikaText.textPickHide, isOn: $hidePikaWhilePicking)
                SettingsDivider()
                SettingsToggle(PikaText.textPickContrasting, isOn: $pickContrastingColor)
                SettingsDivider()
                SettingsToggle(PikaText.textCopyAutomatic, isOn: $copyColorOnPick)
                // The Pro picker shows the colour live in the loupe, so the post-pick overlay
                // (and its duration) is redundant there.
                if pickerStyle != .custom {
                    SettingsDivider()
                    SettingsToggle(PikaText.textShowColorOverlay, isOn: $showColorOverlay)
                    if showColorOverlay {
                        SettingsRow(PikaText.textDuration) {
                            HStack(spacing: 8.0) {
                                Slider(value: $colorOverlayDuration, in: 1.0 ... 5.0, step: 0.5)
                                    .frame(width: 180)
                                    .accessibilityLabel(PikaText.textDuration)
                                Text(String(format: "%.1fs", colorOverlayDuration))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Color

struct ColorSettings: View {
    @Default(.copyFormat) var copyFormat
    @Default(.hideColorNames) var hideColorNames
    @EnvironmentObject var eyedroppers: Eyedroppers

    var body: some View {
        SettingsPage {
            ColorSpaceSettings()
            SettingsGroup(title: PikaText.textCopyTitle) {
                SettingsRow(PikaText.textCopyExport) {
                    Picker(PikaText.textCopyExport, selection: $copyFormat) {
                        ForEach(CopyFormat.allCases, id: \.self) { value in
                            Text(value.localizedString())
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                SettingsDivider()
                // Every format's example, scrolling sideways rather than widening the window.
                ScrollView(.horizontal, showsIndicators: false) {
                    ColorExampleRow(copyFormat: copyFormat, eyedropper: eyedroppers.foreground)
                        .padding(14.0)
                }
            }
            SettingsGroup {
                SettingsBlock {
                    // The picker owns its heading and description (with the refresh state on the right).
                    ColorListPickerView(titleFont: .system(size: 13, weight: .semibold), subtitleFont: .system(size: 11))
                }
                SettingsDivider()
                SettingsToggle(PikaText.textColorNamesDescription, isOn: $hideColorNames)
            }
        }
    }
}

private struct ColorSpaceSettings: View {
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
        case .matchDisplay:
            // On a P3 screen the display's own profile is P3, and copies say so.
            if let space = NSScreen.main?.colorSpace, ColorSpacePreference.isDisplayP3Equivalent(space) {
                return PikaText.textSpaceHintDisplayP3
            }
            return PikaText.textSpaceHintDisplay
        case .space: return PikaText.textSpaceHintOther
        }
    }

    var body: some View {
        SettingsGroup(title: PikaText.textSpaceTitle, footer: hint) {
            SettingsRow(PikaText.textSpaceLabel) {
                Picker(PikaText.textSpaceLabel, selection: $option.onChange { ColorSpacePreference.select($0) }) {
                    ColorSpaceOptions(otherSpaces: otherSpaces)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                // A menu picker is as wide as its longest item, and some spaces' names are long.
                .frame(width: 220)
            }
            SettingsDivider()
            // "Colors don't match? Check a Color", with only the window's name as the link.
            SettingsRow(PikaText.textSpaceMismatchPrompt) {
                Button(PikaText.textMatchTitle) {
                    NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
                }
                .buttonStyle(.link)
            }
            .foregroundStyle(.secondary)
        }
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

// MARK: - Shortcuts

struct ShortcutSettings: View {
    var body: some View {
        SettingsPage {
            // Both global shortcuts the splash offers.
            SettingsGroup(title: PikaText.textHotkeyTitle) {
                SettingsRow(PikaText.textHotkeyDescription) {
                    KeyboardShortcuts.Recorder(for: .togglePika)
                }
                SettingsDivider()
                SettingsRow(PikaText.textPickPair) {
                    KeyboardShortcuts.Recorder(for: .pickPair)
                }
            }
        }
    }
}

/// For a window whose scrolling header runs up behind its transparent titlebar (Settings, Help):
/// lays the scroll view out under the titlebar, and once the header has scrolled up beneath it,
/// fills the titlebar in the way a toolbar would, so content doesn't show behind the window
/// buttons. The window's root view mustn't ignore the safe area itself: the reader here needs
/// the titlebar's height as its top inset.
struct HeaderTitlebarBackdrop: ViewModifier {
    let headerHeight: CGFloat
    /// How far the content has scrolled up.
    @State private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let titlebarHeight = proxy.safeAreaInsets.top
            let scrolledUnder = scrollOffset > headerHeight - titlebarHeight
            content
                .modifier(ScrollOffsetReader(offset: $scrollOffset))
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    TitlebarBackdrop()
                        .frame(height: titlebarHeight)
                        .opacity(scrolledUnder ? 1 : 0)
                        .animation(.easeInOut(duration: 0.15), value: scrolledUnder)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
        }
    }
}

/// Reports how far a scroll view has scrolled. macOS 15 and later: a geometry reader inside the
/// content isn't re-run as it scrolls, so on 14 the offset stays 0 (and the titlebar backdrop off).
private struct ScrollOffsetReader: ViewModifier {
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                offset = newValue
            }
        } else {
            content
        }
    }
}

/// What a toolbar draws behind the titlebar: the bar material with a hairline under it.
private struct TitlebarBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(.bar)
            .overlay(alignment: .bottom) { Divider() }
    }
}

struct SettingsPages_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(SettingsTab.allCases, id: \.self) { tab in
            tab.page.environmentObject(Eyedroppers())
        }
    }
}
