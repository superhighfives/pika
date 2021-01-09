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
                    $0
                }
            }
    }
}

struct ToolbarButtons: View {
    @ViewBuilder
    func getMenu() -> some View {
        let icon = "gearshape"

        if #available(OSX 11.0, *) {
            Menu {
                MenuItems()
            } label: {
                IconImage(name: icon)
            }
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
        } else {
            MenuButton(label: HStack { Spacer(); IconImage(name: icon) }, content: {
                MenuItems()
            })
                .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
                .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0))
                .edgesIgnoringSafeArea(.all)
                .fixedSize()
        }
    }

    var body: some View {
        getMenu()
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
