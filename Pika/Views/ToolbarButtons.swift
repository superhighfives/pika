//
//  ToolbarButtons.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Sparkle
import SwiftUI

struct MenuItems: View {
    var body: some View {
        Button("About", action: {
            NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
        })
        Button("Check for updates...", action: {
            SUUpdater.shared().feedURL = URL(string: PikaConstants.url)
            SUUpdater.shared()?.checkForUpdates(self)
        })
        Button("Preferences...", action: {
            NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
        })
        .modify {
            if #available(OSX 11.0, *) {
                $0.keyboardShortcut(",", modifiers: .command)
            } else {
                // TODO: Look at keyboard shortcut options for 10.5
                $0
            }
        }
        
        Divider()
        
        Button("Quit", action: {
            NSApplication.shared.terminate(self)
        })
        .modify {
            if #available(OSX 11.0, *) {
                $0.keyboardShortcut("q", modifiers: .command)
            } else {
                // TODO: Look at keyboard shortcut options for 10.5
                $0
            }
        }
    }
}

struct ToolbarButtons: View {
    
    @ViewBuilder
    func getMenu() -> some View {
        if #available(OSX 11.0, *) {
            Menu {
                MenuItems()
            } label: {
                IconImage(name: "gear")
            }
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
        } else {
            MenuButton(label: IconImage(name: "gear"), content: {
                MenuItems()
            })
        }
    }
    
    var body: some View {
        Group {
            if #available(OSX 11.0, *) {
                getMenu()
                .frame(alignment: .leading)
                .padding(.horizontal, 16.0)
                .fixedSize()
            } else {
            
            }
        }
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButtons()
    }
}
