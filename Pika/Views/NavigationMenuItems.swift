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
    var body: some View {
        Group {
            Button("\(PikaText.textPickForeground)...", action: {
                NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("d", modifiers: .command)
                    } else {
                        $0
                    }
                }

            Button("\(PikaText.textPickBackground)...", action: {
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

            Button(PikaText.textCopyForeground, action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyForeground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("c", modifiers: .command)
                    } else {
                        $0
                    }
                }

            Button(PikaText.textCopyBackground, action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyBackground), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut("C", modifiers: .command)
                    } else {
                        $0
                    }
                }

            VStack {
                Divider()
            }

            Button(PikaText.textMenuCopyAllAsText, action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyText), to: nil, from: nil)
            })

            Button(PikaText.textMenuCopyAllAsJSON, action: {
                NSApp.sendAction(#selector(AppDelegate.triggerCopyData), to: nil, from: nil)
            })
        }

        VStack {
            Divider()
        }

        Button(PikaText.textColorSwapDetail, action: {
            NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        })
            .modify {
                if #available(OSX 11.0, *) {
                    $0.keyboardShortcut("X", modifiers: .command)
                } else {
                    $0
                }
            }

        Button(PikaText.textColorUndo, action: {
            NSApp.sendAction(#selector(AppDelegate.triggerUndo), to: nil, from: nil)
        })
            .modify {
                if #available(OSX 11.0, *) {
                    $0.keyboardShortcut("z", modifiers: .command)
                } else {
                    $0
                }
            }

        Button(PikaText.textColorRedo, action: {
            NSApp.sendAction(#selector(AppDelegate.triggerRedo), to: nil, from: nil)
        })
            .modify {
                if #available(OSX 11.0, *) {
                    $0.keyboardShortcut("Z", modifiers: .command)
                } else {
                    $0
                }
            }

        VStack {
            Divider()
        }

        Group {
            Button(PikaText.textMenuAbout, action: {
                NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
            })
            Button("\(PikaText.textMenuUpdates)...", action: {
                NSApp.sendAction(#selector(AppDelegate.checkForUpdates), to: nil, from: nil)
            })
            Button(PikaText.textMenuPreferences, action: {
                NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
            })
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.keyboardShortcut(",", modifiers: .command)
                    } else {
                        $0
                    }
                }
            Button(PikaText.textMenuGitHubIssue, action: {
                NSApp.sendAction(#selector(AppDelegate.openGitHubIssue), to: nil, from: nil)
            })
        }

        VStack {
            Divider()
        }

        Button(PikaText.textMenuQuit, action: {
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
