//
//  AppDelegate.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Cocoa
import Defaults
import KeyboardShortcuts
import MetalKit
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.showSplash) var showSplash

    var statusBarItem: NSStatusItem!
    var pikaWindow: NSWindow!
    var splashWindow: NSWindow!
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
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
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
        } else {
            pikaWindow.toolbar!.showsBaselineSeparator = false
            pikaWindow.titleVisibility = .hidden
        }
        let toolbarButtons = NSHostingView(rootView: ToolbarButtons())
        toolbarButtons.frame.size = toolbarButtons.fittingSize
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = toolbarButtons
        titlebarAccessory.layoutAttribute = .trailing
        pikaWindow.addTitlebarAccessoryViewController(titlebarAccessory)

        // Frame and content set up
        pikaWindow.setFrameAutosaveName("Pika Window")
        pikaWindow.contentView = NSHostingView(rootView: contentView)

        // Define global keyboard shortcuts
        KeyboardShortcuts.onKeyUp(for: .togglePika) { [self] in
            if !Defaults[.showSplash] {
                togglePopover(nil)
            }
        }

        // Open splash window
        if showSplash {
            openSplashWindow(nil)
        } else {
            showMainWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            pikaWindow.makeKeyAndOrderFront(self)
        }
        return true
    }

    func startMainWindow() {
        if !pikaWindow.isVisible {
            pikaWindow.fadeIn(nil)
        }
        Defaults[.showSplash] = false
    }

    func showMainWindow() {
        pikaWindow.makeKeyAndOrderFront(nil)
    }

    func hideMainWindow() {
        pikaWindow.orderOut(nil)
    }

    @objc func closeSplashWindow() {
        splashWindow.fadeOut(sender: nil, duration: 0.25, closeSelector: .close, completionHandler: startMainWindow)
    }

    @objc func togglePopover(_: AnyObject?) {
        if pikaWindow.isVisible {
            hideMainWindow()
        } else {
            showMainWindow()
        }
    }

    func createWindow(title: String, size: NSRect, styleMask: NSWindow.StyleMask) -> NSWindow {
        let window = NSWindow(
            contentRect: size,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("\(title) Window")
        window.isReleasedWhenClosed = false
        return window
    }

    @IBAction func openAboutWindow(_: Any?) {
        if aboutWindow == nil {
            aboutWindow = createWindow(title: "About", size: NSRect(x: 0, y: 0, width: 300, height: 300), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView])
            aboutWindow.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openPreferencesWindow(_: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = createWindow(title: "Preferences", size: NSRect(x: 0, y: 0, width: 550, height: 380), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView])
            preferencesWindow.contentView = NSHostingView(rootView: PreferencesView())
        }
        preferencesWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func openSplashWindow(_: Any?) {
        if splashWindow == nil {
            splashWindow = createWindow(title: "Splash", size: NSRect(x: 0, y: 0, width: 600, height: 280), styleMask: [.titled, .fullSizeContentView])
            splashWindow.titleVisibility = .visible
            splashWindow.title = "Welcome to Pika"
            splashWindow.contentView = NSHostingView(rootView: SplashView().edgesIgnoringSafeArea(.all))
        }
        splashWindow.fadeIn(nil)
    }
}
