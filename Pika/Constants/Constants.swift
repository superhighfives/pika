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
    static let ncTriggerUndo = "triggerUndo"
    static let ncTriggerRedo = "triggerRedo"
    static let ncTriggerPreferences = "triggerPreferences"
}

enum PikaText {
    static let textAppName = NSLocalizedString("app.name", comment: "Pika")

    /*
     * Colors
     */

    static let textColorForeground = NSLocalizedString("color.foreground", comment: "Foreground")
    static let textColorBackground = NSLocalizedString("color.background", comment: "Background")
    static let textColorPass = NSLocalizedString("color.wcag.pass", comment: "Pass")
    static let textColorFail = NSLocalizedString("color.wcag.fail", comment: "Fail")
    static let textColorRatio = NSLocalizedString("color.ratio", comment: "Contrast Ratio")
    static let textColorWCAG = NSLocalizedString("color.wcag", comment: "WCAG Compliance")
    static let textColorWCAG30 = NSLocalizedString("color.wcag.30", comment: "WCAG 3:1")
    static let textColorWCAG45 = NSLocalizedString("color.wcag.45", comment: "WCAG 4.5:1")
    static let textColorWCAG70 = NSLocalizedString("color.wcag.70", comment: "WCAG 7:1")
    static let textColorSwap = NSLocalizedString("color.swap", comment: "Swap")
    static let textColorSwapDetail = NSLocalizedString("color.swap.detail", comment: "Swap colors")
    static let textColorUndo = NSLocalizedString("color.undo", comment: "Undo")
    static let textColorRedo = NSLocalizedString("color.redo", comment: "Redo")
    static let textColorCopy = NSLocalizedString("color.copy", comment: "Copy")
    static let textColorCopied = NSLocalizedString("color.copy.toast", comment: "Copied")

    /*
     * Menu
     */

    static let textMenuAbout = NSLocalizedString("menu.about", comment: "About")
    static let textMenuUpdates = NSLocalizedString("menu.updates", comment: "Check for updates")
    static let textMenuPreferences = NSLocalizedString("menu.preferences", comment: "Preferences")
    static let textMenuQuit = NSLocalizedString("menu.quit", comment: "Quit Pika")

    // Navigation
    static let textMenuCopyAllAsText = NSLocalizedString("color.copy.text", comment: "Copy all as text")
    static let textMenuCopyAllAsJSON = NSLocalizedString("color.copy.data", comment: "Copy all as JSON")

    /*
     * Touchbar
     */

    static let textColorNormal = NSLocalizedString("color.wcag.normal", comment: "Normal")
    static let textColorLargeAbbr = NSLocalizedString("color.wcag.large.abbr", comment: "LG")
    static let textColorLarge = NSLocalizedString("color.wcag.large", comment: "Large")

    /*
     * Splash
     */

    static let textSplashLaunch = NSLocalizedString("splash.hotkey", comment: "Global shortcut")
    static let textSplashHotkey = NSLocalizedString("splash.launch", comment: "Launch at login")
    static let textSplashStart = NSLocalizedString("splash.start", comment: "Get started")

    /*
     * About
     */

    static let textAboutWebsite = NSLocalizedString("app.website", comment: "Website")
    static let textAboutGitHub = NSLocalizedString("app.github", comment: "GitHub")
    static let textAboutBy = NSLocalizedString("app.designed", comment: "Designed by")
    static let textAboutVersion = NSLocalizedString("app.version", comment: "Version")
    static let textAboutBuild = NSLocalizedString("app.build", comment: "Build")
    static let textAboutUnknown = NSLocalizedString("app.unknown", comment: "Unknown")

    // Keyboard shortcuts
    static let textPickForeground = NSLocalizedString("color.pick.foreground", comment: "Pick foreground")
    static let textPickBackground = NSLocalizedString("color.pick.background", comment: "Pick background")
    static let textCopyForeground = NSLocalizedString("color.copy.foreground", comment: "Copy foreground")
    static let textCopyBackground = NSLocalizedString("color.copy.background", comment: "Copy background")

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
    static let textFloatDescription = NSLocalizedString(
        "preferences.float.description",
        comment: "Float above windows"
    )

    // App Settings
    static let textAppTitle = NSLocalizedString("preferences.app.title", comment: "App Settings")
    static let textAppMenubarTitle = NSLocalizedString("preferences.app.menubar.title", comment: "Menu bar")
    static let textAppMenubarDescription = NSLocalizedString("preferences.app.menubar.description", comment: "Show in menu bar")
    static let textAppDockTitle = NSLocalizedString("preferences.app.dock.title", comment: "Dock")
    static let textAppDockDescription = NSLocalizedString("preferences.app.dock.description", comment: "Show in dock")
    static let textAppHiddenTitle = NSLocalizedString("preferences.app.hidden.title", comment: "Hidden")
    static let textAppHiddenDescription = NSLocalizedString("preferences.app.hidden.description", comment: "Hide app")

    // Appearance Settings
    static let textAppearanceTitle = NSLocalizedString("preferences.appearance.title", comment: "Appearance")
    static let textAppearanceWeightTitle = NSLocalizedString("preferences.appearance.weight.title", comment: "Weight")
    static let textAppearanceWeightDescription = NSLocalizedString(
        "preferences.appearance.weight.description",
        comment: "View WCAG compliance by weight, from normal to large"
    )
    static let textAppearanceContrastTitle = NSLocalizedString(
        "preferences.appearance.contrast.title",
        comment: "Contrast"
    )
    static let textAppearanceContrastDescription = NSLocalizedString(
        "preferences.appearance.contrast.description",
        comment: "View WCAG compliance by contrast, from 3:1 to 7:1"
    )

    // Copy Settings
    static let textCopyTitle = NSLocalizedString("preferences.copy.title", comment: "Copy Settings")
    static let textCopyExport = NSLocalizedString("preferences.copy.export", comment: "Export color for")
    static let textCopyExportExample = NSLocalizedString("preferences.copy.export.example", comment: "Export example")
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
