//
//  AppDelegate.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Cocoa
import KeyboardShortcuts
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var pikaWindow: NSWindow!
    var aboutWindow: NSWindow!
    var preferencesWindow: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        // Create the status item
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIcon")
            button.action = #selector(togglePopover(_:))
        }

        // Defined content view
        let contentView = ContentView()
            .frame(minWidth: 320,
                   idealWidth: 320,
                   maxWidth: 500,
                   minHeight: 150,
                   idealHeight: 150,
                   maxHeight: 350,
                   alignment: .center)

        // Create primary window
        pikaWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .borderless],
            backing: .buffered, defer: false
        )
        pikaWindow.isReleasedWhenClosed = false
        pikaWindow.center()
        pikaWindow.title = "Pika"
        pikaWindow.level = .floating
        pikaWindow.isMovableByWindowBackground = true
        pikaWindow.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true

        // Set up toolbar
        pikaWindow.toolbar = NSToolbar()
        pikaWindow.toolbarStyle = .unifiedCompact
        let toolbarButtons = NSHostingView(rootView: ToolbarButtons())
        toolbarButtons.frame.size = toolbarButtons.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = toolbarButtons
        titlebarAccessory.layoutAttribute = .trailing
        pikaWindow.addTitlebarAccessoryViewController(titlebarAccessory)

        // Frame and content set up
        pikaWindow.makeMain()
        pikaWindow.setFrameAutosaveName("Pika Window")
        pikaWindow.contentView = NSHostingView(rootView: contentView)

        // Bring window to front
        showMainWindow()

        // Define global keyboard shortcuts
        KeyboardShortcuts.onKeyUp(for: .togglePika) { [self] in
            togglePopover(nil)
        }
    }

    func showMainWindow() {
        pikaWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideMainWindow() {
        pikaWindow.orderOut(nil)
    }

    @objc func togglePopover(_: AnyObject?) {
        if pikaWindow.isVisible {
            hideMainWindow()
        } else {
            showMainWindow()
        }
    }

    func createWindow(title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false
        return window
    }

    @IBAction func openAboutWindow(_: Any) {
        if aboutWindow == nil {
            aboutWindow = createWindow(title: "About")
            aboutWindow.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = createWindow(title: "Preferences")
            preferencesWindow.contentView = NSHostingView(rootView: PreferencesView())
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
}
