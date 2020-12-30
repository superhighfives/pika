//
//  AppDelegate.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Cocoa
import SwiftUI
import Sparkle
import KeyboardShortcuts

struct ToolbarButtons: View {
  var body: some View {
    Menu {
      Button("About", action: {
        NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from:nil)
      })
      Button("Check for updates...", action: {
        SUUpdater.shared().feedURL = URL(string: "https://")
        SUUpdater.shared()?.checkForUpdates(self)
      })
      Button("Preferences...", action: {
        NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from:nil)
      })
      .keyboardShortcut(",", modifiers: .command)
      Divider()
      Button("Quit", action: {
        NSApplication.shared.terminate(self)
      })
      } label: {
        Image(systemName: "gear")
      }
    .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
    .frame(alignment: .leading)
    .padding(.horizontal, 16.0)
    .fixedSize()
  }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var statusBarItem: NSStatusItem!
  var pikaWindow: NSWindow!
  var aboutWindow: NSWindow!
  var preferencesWindow: NSWindow!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    let contentView = ContentView()
      .frame(minWidth: 320, idealWidth: 320, maxWidth: 500, minHeight: 150, idealHeight: 150, maxHeight: 350, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)

    pikaWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .borderless],
      backing: .buffered, defer: false)
    pikaWindow.isReleasedWhenClosed = false
    pikaWindow.center()
    pikaWindow.title = "Pika"
    pikaWindow.level = .floating
    pikaWindow.isMovableByWindowBackground = true
    pikaWindow.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isEnabled = false
    pikaWindow.toolbar = NSToolbar()
        
    let toolbarButtons = NSHostingView(rootView: ToolbarButtons())
    toolbarButtons.frame.size = toolbarButtons.fittingSize
    
    let titlebarAccessory = NSTitlebarAccessoryViewController()
    titlebarAccessory.view = toolbarButtons
    titlebarAccessory.layoutAttribute = .trailing
    pikaWindow.addTitlebarAccessoryViewController(titlebarAccessory)
    
    pikaWindow.setFrameAutosaveName("Pika Window")
    pikaWindow.contentView = NSHostingView(rootView: contentView)
    pikaWindow.makeKeyAndOrderFront(nil)
    
    // Create the status item
    self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
    
    if let button = self.statusBarItem.button {
      button.image = NSImage(named: "StatusBarIcon")
      button.action = #selector(togglePopover(_:))
    }
    
    KeyboardShortcuts.onKeyUp(for: .togglePika) { [self] in
      togglePopover(nil)
    }
  }
  
  @objc func togglePopover(_ sender: AnyObject?) {
    pikaWindow.isVisible ? pikaWindow.orderOut(nil) : pikaWindow.makeKeyAndOrderFront(nil)
  }
  
  func createWindow(title: String) -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: false)
    window.level = .floating
    window.center()
    window.setFrameAutosaveName("\(title) Window")
    window.isReleasedWhenClosed = false
    return window
  }
  
  @objc func openAboutWindow() {
    if nil == aboutWindow { // create once
      aboutWindow = createWindow(title: "About")
      aboutWindow.contentView = NSHostingView(rootView: AboutView())
    }
    aboutWindow.makeKeyAndOrderFront(nil)
  }

  @objc func openPreferencesWindow() {
    if nil == preferencesWindow { // create once
      preferencesWindow = createWindow(title: "Preferences")
      preferencesWindow.contentView = NSHostingView(rootView: PreferencesView())
    }
    preferencesWindow.makeKeyAndOrderFront(nil)
  }
  
  @IBAction func handlePreferencesShortcut(_ sender: Any) {
    openPreferencesWindow()
  }
}

