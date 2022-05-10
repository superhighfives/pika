import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Visualisation()
                Image("AppSplash")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 140.0)
                    .offset(x: 0.0, y: 5.0)
            }
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
                    .modify {
                        if #available(OSX 11.0, *) {
                            $0.keyboardShortcut(.defaultAction)
                                .accentColor(.accentColor)
                        } else {
                            $0
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: 50.0)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
