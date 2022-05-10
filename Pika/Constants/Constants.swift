import Defaults
import KeyboardShortcuts
import SwiftUI

// swiftlint:disable trailing_comma

extension KeyboardShortcuts.Name {
    static let togglePika = Self("togglePika")
}

enum PikaConstants {
    // Release URL
    static func url() -> String {
        Defaults[.betaUpdates]
            ? "https://superhighfives.com/releases/pika/betas"
            : "https://superhighfives.com/releases/pika"
    }

    // Initial colors
    static let initialColors = [
        NSColor(r: 143.0, g: 15.0, b: 208.0),
        NSColor(r: 224.0, g: 53.0, b: 139.0),
        NSColor(r: 20.0, g: 63.0, b: 245.0),
        NSColor(r: 235.0, g: 54.0, b: 75.0),
        NSColor(r: 182.0, g: 26.0, b: 129.0),
        NSColor(r: 88.0, g: 32.0, b: 228.0),
        NSColor(r: 191.0, g: 19.0, b: 186.0),
        NSColor(r: 119.0, g: 77.0, b: 178.0),
        NSColor(r: 14.0, g: 35.0, b: 204.0),
        NSColor(r: 188.0, g: 42.0, b: 97.0),
    ]

    // Notification Center constants
    static let ncTriggerCopyForeground = "triggerCopyForeground"
    static let ncTriggerCopyBackground = "triggerCopyBackground"
    static let ncTriggerCopyText = "triggerCopyText"
    static let ncTriggerCopyData = "triggerCopyData"
    static let ncTriggerPickForeground = "triggerPickForeground"
    static let ncTriggerPickBackground = "triggerPickBackground"
    static let ncTriggerSwap = "triggerSwap"
    static let ncTriggerPreferences = "triggerPreferences"
}

enum PikaText {
    
    /*
     * Splash
     */
    
    static let textSplashLaunch = NSLocalizedString("splash.hotkey", comment: "Global shortcut")
    static let textSplashHotkey = NSLocalizedString("splash.launch", comment: "Launch at login")
    static let textSplashStart = NSLocalizedString("splash.start", comment: "Get started")
  
    /*
     * Preferences
     */
  
    // General Settings
    static let textGeneralTitle = NSLocalizedString("preferences.general.title", comment: "General Settings")
    static let textLaunchDescription = NSLocalizedString(
        "preferences.launch.description",
        comment: "Launch at login"
    )
    static let textIconDescription = NSLocalizedString(
        "preferences.icon.description",
        comment: "Hide menu bar icon"
    )
    static let textBetaDescription = NSLocalizedString(
        "preferences.beta.description",
        comment: "Subscribe to beta releases"
    )
    static let textSelectionTitle = NSLocalizedString("preferences.selection.title", comment: "Selection Settings")
    static let textPickHide = NSLocalizedString("preferences.pick.hide", comment: "Hide Pika while picking")
    static let textColorNamesDescription = NSLocalizedString(
        "preferences.names.description",
        comment: "Hide color names"
    )

    // Copy Settings
    static let textCopyTitle = NSLocalizedString("preferences.copy.title", comment: "Copy Settings")
    static let textCopyExport = NSLocalizedString("preferences.copy.export", comment: "Export color for")
    static let textCopyFormat = NSLocalizedString("preferences.copy.format", comment: "Export Format")
    static let textCopyAutomatic = NSLocalizedString(
        "preferences.copy.automatic",
        comment: "Automatically copy color to clipboard on pick"
    )

    // Color Format
    static let textFormatTitle = NSLocalizedString("preferences.format.title", comment: "Color Format")
    static let textFormatDescription = NSLocalizedString(
        "preferences.space.description",
        comment: "Set your RGB color space"
    )
    static let textSpaceTitle = NSLocalizedString("preferences.space.title", comment: "Color Space")
    static let textSystemDefault = NSLocalizedString("preferences.space.default", comment: "System Default")

    // Global Shortcut
    static let textHotkeyTitle = NSLocalizedString("preferences.hotkey.title", comment: "Global Shortcut")
    static let textHotkeyDescription = NSLocalizedString(
        "preferences.hotkey.description",
        comment: "Set a global hotkey shortcut to invoke Pika"
    )
}
