import Defaults
import SwiftUI

struct MenuGroup<Content>: View where Content: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        if #available(macOS 11.0, *) {
            Menu(title) {
                content()
            }
        } else {
            MenuButton(label: Text(title), content: content)
        }
    }
}

struct NavigationMenuItems: View {
    @Default(.hidePikaWhilePicking) var hidePikaWhilePicking
    @Default(.copyColorOnPick) var copyColorOnPick
    @Default(.hideFormatOnCopy) var hideFormatOnCopy

    var body: some View {
        Group {
            Toggle(isOn: $hidePikaWhilePicking) {
                Text(NSLocalizedString("color.pick.hide", comment: "Hide Pika while picking"))
            }
            Toggle(isOn: $copyColorOnPick) {
                Text(NSLocalizedString("preferences.copy.description", comment: "Copy value when picking"))
            }
        }
        VStack {
            Divider()
        }
        Group {
            Button("\(NSLocalizedString("color.pick.foreground", comment: "Pick foreground"))...", action: {
                NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("d", modifiers: .command)
                    } else {
                        $0
                    }
                }

            Button("\(NSLocalizedString("color.pick.background", comment: "Pick background"))...", action: {
                NSApp.sendAction(#selector(AppDelegate.triggerPickBackground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("D", modifiers: .command)
                    } else {
                        $0
                    }
                }

            VStack {
                Divider()
            }

            Button(NSLocalizedString("color.copy.foreground", comment: "Copy foreground"), action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyForeground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("c", modifiers: .command)
                    } else {
                        $0
                    }
                }

            Button(NSLocalizedString("color.copy.background", comment: "Copy background"), action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyBackground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("C", modifiers: .command)
                    } else {
                        $0
                    }
                }

            Toggle(isOn: $hideFormatOnCopy) {
                Text(NSLocalizedString("color.copy.format", comment: "Hide format when copying"))
            }

            VStack {
                Divider()
            }

            Button(NSLocalizedString("color.copy.text", comment: "Copy all as text"), action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyText), to: nil, from: nil)
            })

            Button(NSLocalizedString("color.copy.data", comment: "Copy all as JSON"), action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyData), to: nil, from: nil)
            })
        }

        VStack {
            Divider()
        }

        Button(NSLocalizedString("color.swap.detail", comment: "Swap Colors"), action: {
            NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        })
            .modify {
                if #available(OSX 11.0, *) {
                    $0.keyboardShortcut("X", modifiers: .command)
                } else {
                    $0
                }
            }

        VStack {
            Divider()
        }

        Group {
            Button(NSLocalizedString("menu.about", comment: "About"), action: {
                NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
            })
            Button("\(NSLocalizedString("menu.updates", comment: "Check for updates"))...", action: {
                NSApp.sendAction(#selector(AppDelegate.checkForUpdates), to: nil, from: nil)
            })
            Button(NSLocalizedString("menu.preferences", comment: "Preferences"), action: {
                NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut(",", modifiers: .command)
                    } else {
                        $0
                    }
                }
        }

        VStack {
            Divider()
        }

        Button(NSLocalizedString("menu.quit", comment: "Quit"), action: {
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

struct NavigationItems_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenuItems()
    }
}
