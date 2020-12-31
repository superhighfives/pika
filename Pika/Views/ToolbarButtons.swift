//
//  ToolbarButtons.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Sparkle
import SwiftUI

struct ToolbarButtons: View {
    var body: some View {
        Menu {
            Button("About", action: {
                NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
            })
            Button("Check for updates...", action: {
                SUUpdater.shared().feedURL = URL(string: "https://")
                SUUpdater.shared()?.checkForUpdates(self)
            })
            Button("Preferences...", action: {
                NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
            })
                .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quit", action: {
                NSApplication.shared.terminate(self)
            })
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "gear")
        }
        .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
        .frame(alignment: .leading)
        .padding(.horizontal, 16.0)
        .fixedSize()
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButtons()
    }
}
