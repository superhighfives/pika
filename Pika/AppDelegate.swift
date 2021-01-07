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
            .frame(minWidth: 380,
                   idealWidth: 380,
                   maxWidth: 500,
                   minHeight: 150,
                   idealHeight: 150,
                   maxHeight: 350,
                   alignment: .center)

        // Create primary window
        pikaWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 150),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .borderless],
            backing: .buffered, defer: false
        )
        pikaWindow.isReleasedWhenClosed = false
        pikaWindow.center()
        pikaWindow.title = "Pika"
        pikaWindow.level = .floating
        pikaWindow.isMovableByWindowBackground = true
        pikaWindow.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isEnabled = false
        pikaWindow.titlebarAppearsTransparent = true

        // Set up toolbar
        pikaWindow.toolbar = NSToolbar()
        if #available(OSX 11.0, *) {
            pikaWindow.toolbarStyle = .unifiedCompact
        }
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

    func createWindow(title: String, size: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: size,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.level = .floating
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false
        return window
    }

    @IBAction func openAboutWindow(_: Any?) {
        if aboutWindow == nil {
            aboutWindow = createWindow(title: "About", size: NSRect(x: 0, y: 0, width: 300, height: 300))
            aboutWindow.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = createWindow(title: "Preferences", size: NSRect(x: 0, y: 0, width: 550, height: 380))
            preferencesWindow.contentView = NSHostingView(rootView: PreferencesView())
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
}
