import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(red: 0.4, green: 0.0, blue: 0.7)
                Visualisation()
                SplashEye()
                    .frame(maxWidth: 210.0)
                    .offset(x: 0.0, y: 5.0)
                    .padding(.vertical, 48.0)
            }
            .frame(maxHeight: .infinity)
            Divider()
            HStack(spacing: 16.0) {
                HStack {
                    Text(PikaText.textSplashLaunch)
                    KeyboardShortcuts.Recorder(for: .togglePika)
                }

                Divider()

                LaunchAtLogin.Toggle {
                    Text(PikaText.textSplashHotkey)
                }

                Divider()

                Button(action: {
                    NSApp.sendAction(#selector(AppDelegate.closeSplashWindow), to: nil, from: nil)
                }, label: { Text(PikaText.textSplashStart) })
                    .keyboardShortcut(.defaultAction)
                    .tint(.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: 50.0)
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
