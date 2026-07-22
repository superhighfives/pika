import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SplashView: View {
    @Default(.pickerStyle) var pickerStyle
    @State private var hostWindow: NSWindow?
    @State private var pendingRelaunch = false

    // The custom picker is only the active choice once permission exists. "Get started" is
    // the primary action only then — otherwise Grant Permission is the primary call.
    private var customActive: Bool { CustomColorPickSession.isAvailable && pickerStyle == .custom }

    var body: some View {
        HStack(spacing: 0) {
            // Left: branded visualisation (shader + Liquid Glass eye).
            ZStack {
                Color(red: 0.4, green: 0.0, blue: 0.7)
                Visualisation()
                SplashEye()
                    .frame(maxWidth: 150.0)
                    .offset(x: 0.0, y: 5.0)
            }
            .frame(width: 260.0)
            .frame(maxHeight: .infinity)

            // Right: explained setup list with a pinned footer.
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20.0) {
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text(PikaText.textSplashSetupTitle)
                                .font(.system(size: 20, weight: .bold))
                            Text(PikaText.textSplashSetupSubtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        SplashSettingRow(
                            title: PikaText.textSplashLaunch,
                            subtitle: PikaText.textSplashShortcutSubtitle
                        ) {
                            KeyboardShortcuts.Recorder(for: .togglePika)
                        }

                        SplashSettingRow(
                            title: PikaText.textPickPair,
                            subtitle: PikaText.textSplashPairSubtitle
                        ) {
                            KeyboardShortcuts.Recorder(for: .pickPair)
                        }

                        SplashSettingRow(
                            title: PikaText.textSplashHotkey,
                            subtitle: PikaText.textSplashLaunchSubtitle
                        ) {
                            LaunchAtLogin.Toggle {}
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        VStack(alignment: .leading, spacing: 8.0) {
                            Text(PikaText.textPickerStyleTitle)
                                .font(.system(size: 13, weight: .semibold))
                            PickerChoiceView(pendingRelaunch: $pendingRelaunch)
                        }
                    }
                    .padding(24.0)
                }

                Divider()

                HStack(spacing: 12.0) {
                    Text(PikaText.textSplashFooter)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 12.0)
                    if customActive {
                        Button(action: handleGetStarted, label: { Text(PikaText.textSplashStart) })
                            .keyboardShortcut(.defaultAction)
                            .tint(Color.accentColor)
                    } else {
                        Button(action: handleGetStarted, label: { Text(PikaText.textSplashStart) })
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 24.0)
                .padding(.vertical, 12.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .background(SplashWindowAccessor(window: $hostWindow))
    }

    private func closeSplash() {
        NSApp.sendAction(#selector(AppDelegate.closeSplashWindow), to: nil, from: nil)
    }

    // If the user is leaving on the system picker, nudge them toward the custom one once
    // before closing. Choosing "Enable" runs the permission flow and keeps the splash open
    // so they see the result; otherwise we proceed with the system picker.
    private func handleGetStarted() {
        guard pickerStyle != .custom else { closeSplash(); return }

        let alert = NSAlert()
        alert.messageText = PikaText.textSplashConfirmTitle
        alert.informativeText = PikaText.textSplashConfirmBody
        alert.alertStyle = .informational
        alert.addButton(withTitle: PikaText.textSplashConfirmEnable)
        alert.addButton(withTitle: PikaText.textSplashConfirmContinue)

        let handle: (NSApplication.ModalResponse) -> Void = { response in
            if response == .alertFirstButtonReturn {
                PickerChoiceView.requestAccess(pendingRelaunch: $pendingRelaunch)
            } else {
                closeSplash()
            }
        }

        if let hostWindow {
            alert.beginSheetModal(for: hostWindow, completionHandler: handle)
        } else {
            handle(alert.runModal())
        }
    }
}

/// One explained setting row: title + subtitle on the left, a control on the right.
private struct SplashSettingRow<Control: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 12.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12.0)
            control
        }
    }
}

/// The System vs Custom picker comparison, shared by the splash and Settings. Two selectable
/// tiles — System (selected by default) and Custom — with Custom disabled until Screen
/// Recording permission exists, plus a primary "Grant Permission" action and, once requested,
/// relaunch guidance (a first-time grant only takes effect after relaunch).
struct PickerChoiceView: View {
    @Binding var pendingRelaunch: Bool
    @Default(.pickerStyle) private var pickerStyle

    private var hasPermission: Bool { CustomColorPickSession.isAvailable }
    // Custom is only truly active once permission exists; until then System stays selected
    // and the Custom tile is disabled.
    private var customActive: Bool { hasPermission && pickerStyle == .custom }

    var body: some View {
        VStack(spacing: 10.0) {
            HStack(spacing: 16.0) {
                PickerComparisonTile(
                    style: .system,
                    title: PikaText.textPickerSystemTitle,
                    description: PikaText.textPickerSystemDescription,
                    selected: !customActive,
                    disabled: false,
                    onSelect: { pickerStyle = .system; pendingRelaunch = false }
                )
                PickerComparisonTile(
                    style: .custom,
                    title: PikaText.textPickerCustomTitle,
                    description: PikaText.textPickerCustomDescription,
                    selected: customActive,
                    disabled: !hasPermission,
                    onSelect: { pickerStyle = .custom }
                )
            }
            .frame(height: 96.0)

            permissionArea
        }
        .padding(12.0)
        .background(
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1.0)
                .allowsHitTesting(false)
        )
    }

    // Beneath the tiles: the primary permission CTA until Screen Recording is granted (and
    // relaunch guidance once requested). Once permission is live the tiles are the whole
    // control, so there's nothing more to show.
    @ViewBuilder private var permissionArea: some View {
        if !hasPermission, pendingRelaunch {
            VStack(spacing: 6.0) {
                Text(PikaText.textPickerRelaunchNote)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: { CustomColorPickSession.relaunch() },
                       label: { Text(PikaText.textPickerRelaunchButton) })
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
        } else if !hasPermission {
            VStack(spacing: 6.0) {
                Button(action: { Self.requestAccess(pendingRelaunch: $pendingRelaunch) }, label: {
                    Text(PikaText.textPickerGrantButton).frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                Text(PikaText.textSplashPickerPermission)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Requests Screen Recording permission and persists the intent (`.custom`) so that once
    // permission is live — which needs a relaunch — the picker is already selected. Shared
    // with the splash's "Get started" nudge so both drive the same state.
    static func requestAccess(pendingRelaunch: Binding<Bool>) {
        CustomColorPickSession.requestAccess { granted in
            Defaults[.pickerStyle] = .custom
            pendingRelaunch.wrappedValue = !granted
        }
    }
}

/// A selectable comparison tile: a static preview mock of a picker plus its title. System
/// is always selectable; Custom is disabled until Screen Recording permission exists. Not a
/// live capture — the mocks are illustrative.
private enum PickerPreviewKind { case system, custom }

private struct PickerComparisonTile: View {
    let style: PickerPreviewKind
    let title: String
    let description: String
    let selected: Bool
    let disabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect, label: {
            preview.frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .buttonStyle(AppearanceButtonStyle(title: title, description: description, selected: selected))
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }

    @ViewBuilder private var preview: some View {
        switch style {
        case .system: basicMock
        case .custom: proMock
        }
    }

    // Monochrome white-on-dark, matching the app-mode preview art: translucent white
    // fills, white line-art, no colour, no container borders.

    // Basic picker: a plain, dull loupe — a single flat disc with a faint crosshair.
    private var basicMock: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08))
            crosshair(opacity: 0.35)
        }
        .frame(width: 40.0, height: 40.0)
    }

    // Pro picker: a mini loupe with a brighter sample area, skeleton readout bars for the
    // format and contrast, and a pass dot — richer, showing off the live overlay.
    private var proMock: some View {
        VStack(spacing: 3.0) {
            ZStack {
                RoundedRectangle(cornerRadius: 3.0, style: .continuous)
                    .fill(Color.white.opacity(0.22))
                crosshair(opacity: 0.7)
            }
            .frame(height: 18.0)

            HStack(spacing: 4.0) {
                skeletonBar(width: 24.0, opacity: 0.4)
                Spacer(minLength: 0.0)
                Circle().fill(Color.white.opacity(0.55)).frame(width: 5.0, height: 5.0)
            }
        }
        .padding(.horizontal, 5.0)
        .padding(.top, 5.0)
        .padding(.bottom, 3.0)
        .frame(width: 52.0)
        .background(
            RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func crosshair(opacity: Double) -> some View {
        Rectangle()
            .strokeBorder(Color.white.opacity(opacity), lineWidth: 2.0)
            .frame(width: 9.0, height: 9.0)
    }

    private func skeletonBar(width: CGFloat, opacity: Double) -> some View {
        Capsule().fill(Color.white.opacity(opacity)).frame(width: width, height: 3.0)
    }
}

/// Reports the hosting `NSWindow` up to SwiftUI so the permission flow can lower the
/// splash's window level while the system TCC dialog is shown.
private struct SplashWindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { window = view.window }
        return view
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        DispatchQueue.main.async {
            if window == nil { window = nsView.window }
        }
    }
}

// The splash eye mirrors the app icon: a flat white eye (Eye.svg) that the OS
// renders as Liquid Glass on macOS 26, refracting the shader behind it. Older
// systems fall back to a clean white eye with a soft shadow, matching the
// icon's neutral-shadow + translucency recipe.
struct SplashEye: View {
    private var eye: some View {
        Image("SplashEye")
            .resizable()
            .scaledToFit()
    }

    var body: some View {
        // Fake the icon's Liquid Glass eye with static layers (focus-independent,
        // unlike .glassEffect): a translucent white base that picks up the shader,
        // a bright upper-left specular sheen (icon light angle is -45°) via
        // .plusLighter, and a subtle lower-right darkening via .multiply for depth.
        eye
            .foregroundStyle(.white)
            .overlay {
                // Bright upper-left specular sheen (icon light angle is -45°).
                LinearGradient(
                    colors: [.white, .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .blendMode(.plusLighter)
                .mask { eye }
            }
            .opacity(0.9)
            .mask {
                // Vertical alpha falloff: solid up top, dissolving to translucent
                // through the bottom half for a liquid-glass feel.
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white, location: 0.3),
                        .init(color: .white.opacity(0.0), location: 0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .shadow(color: .black.opacity(0.3), radius: 8.0, y: 4.0)
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
