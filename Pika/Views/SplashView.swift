//
//  SplashView.swift
//  Pika
//
//  Created by Charlie Gleason on 06/01/2021.
//

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
                    .frame(maxWidth: 150.0)
            }
            Divider()
            HStack(spacing: 15.0) {
                HStack {
                    Text("Set shortcut")
                        .font(.callout)
                    KeyboardShortcuts.Recorder(for: .togglePika)
                }

                Divider()

                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }

                Divider()

                Button(action: {
                    NSApp.sendAction(#selector(AppDelegate.closeSplashWindow), to: nil, from: nil)
                }, label: { Text("Get Started") })
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
