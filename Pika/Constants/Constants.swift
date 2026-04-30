import Defaults
import KeyboardShortcuts
import SwiftUI

// swiftlint:disable line_length

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

    static let pikaWebsiteURL = "https://superhighfives.com/pika"
    static let gitHubRepoURL = "https://github.com/superhighfives/pika"
    static let gitHubIssueURL = "https://github.com/superhighfives/pika/issues/new/choose"
    static let charlieGleasonWebsiteURL = "https://charliegleason.com"
    static let pikaHelpURL = "https://superhighfives.com/pika/help"
    static let macAppStoreURL = "https://apps.apple.com/us/app/pika/id6739170421"

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
    static let ncTriggerSystemPickerForeground = "triggerSystemPickerForeground"
    static let ncTriggerSystemPickerBackground = "triggerSystemPickerBackground"
    static let ncTriggerSwap = "triggerSwap"
    static let ncTriggerUndo = "triggerUndo"
    static let ncTriggerRedo = "triggerRedo"
    static let ncTriggerPreferences = "triggerPreferences"
    static let ncTriggerFormatHex = "triggerFormatHex"
    static let ncTriggerFormatRGB = "triggerFormatRGB"
    static let ncTriggerFormatHSB = "triggerFormatHSB"
    static let ncTriggerFormatHSL = "triggerFormatHSL"
    static let ncTriggerFormatOpenGL = "triggerFormatOpenGL"
    static let ncTriggerFormatLAB = "triggerFormatLAB"
    static let ncTriggerFormatOKLCH = "triggerFormatOKLCH"
    static let ncTriggerQuit = "triggerQuit"
    static let ncColorPicked = "colorPicked"
    static let ncToggleHistory = "toggleHistory"
    static let ncToggleColorPreview = "toggleColorPreview"
    static let ncToggleCompliance = "toggleCompliance"
    static let ncHistoryPrevious = "historyPrevious"
    static let ncHistoryNext = "historyNext"
    static let ncHistoryDelete = "historyDelete"
    static let ncSavePalette = "savePalette"
    static let ncExportPalette = "exportPalette"
    static let ncSystemColorChanged = "systemColorChanged"

    // Disabled formats for SwiftUI copy format
    static let disabledFormats: [ColorFormat] = [.hex, .hsl, .opengl, .lab, .oklch]
}

extension Notification.Name {
    static let triggerPickForeground = Notification.Name(PikaConstants.ncTriggerPickForeground)
    static let triggerPickBackground = Notification.Name(PikaConstants.ncTriggerPickBackground)
    static let triggerCopyForeground = Notification.Name(PikaConstants.ncTriggerCopyForeground)
    static let triggerCopyBackground = Notification.Name(PikaConstants.ncTriggerCopyBackground)
    static let triggerCopyText = Notification.Name(PikaConstants.ncTriggerCopyText)
    static let triggerCopyData = Notification.Name(PikaConstants.ncTriggerCopyData)
    static let triggerSystemPickerForeground = Notification.Name(PikaConstants.ncTriggerSystemPickerForeground)
    static let triggerSystemPickerBackground = Notification.Name(PikaConstants.ncTriggerSystemPickerBackground)
    static let triggerSwap = Notification.Name(PikaConstants.ncTriggerSwap)
    static let triggerUndo = Notification.Name(PikaConstants.ncTriggerUndo)
    static let triggerRedo = Notification.Name(PikaConstants.ncTriggerRedo)
    static let triggerPreferences = Notification.Name(PikaConstants.ncTriggerPreferences)
    static let triggerFormatHex = Notification.Name(PikaConstants.ncTriggerFormatHex)
    static let triggerFormatRGB = Notification.Name(PikaConstants.ncTriggerFormatRGB)
    static let triggerFormatHSB = Notification.Name(PikaConstants.ncTriggerFormatHSB)
    static let triggerFormatHSL = Notification.Name(PikaConstants.ncTriggerFormatHSL)
    static let triggerFormatOpenGL = Notification.Name(PikaConstants.ncTriggerFormatOpenGL)
    static let triggerFormatLAB = Notification.Name(PikaConstants.ncTriggerFormatLAB)
    static let triggerFormatOKLCH = Notification.Name(PikaConstants.ncTriggerFormatOKLCH)
    static let triggerQuit = Notification.Name(PikaConstants.ncTriggerQuit)
    static let colorPicked = Notification.Name(PikaConstants.ncColorPicked)
    static let toggleHistory = Notification.Name(PikaConstants.ncToggleHistory)
    static let toggleColorPreview = Notification.Name(PikaConstants.ncToggleColorPreview)
    static let toggleCompliance = Notification.Name(PikaConstants.ncToggleCompliance)
    static let historyPrevious = Notification.Name(PikaConstants.ncHistoryPrevious)
    static let historyNext = Notification.Name(PikaConstants.ncHistoryNext)
    static let historyDelete = Notification.Name(PikaConstants.ncHistoryDelete)
    static let savePalette = Notification.Name(PikaConstants.ncSavePalette)
    static let exportPalette = Notification.Name(PikaConstants.ncExportPalette)
    static let systemColorChanged = Notification.Name(PikaConstants.ncSystemColorChanged)
}

enum PikaText {
    static let textAppName = NSLocalizedString("app.name", comment: "Pika")

    /*
     * General
     */

    static let textCancel = NSLocalizedString("general.cancel", comment: "Cancel")
    static let textClear = NSLocalizedString("general.clear", comment: "Clear")

    /*
     * Colors
     */

    static let textColorForeground = NSLocalizedString("color.foreground", comment: "Foreground")
    static let textColorBackground = NSLocalizedString("color.background", comment: "Background")
    static let textColorPass = NSLocalizedString("color.wcag.pass", comment: "Pass")
    static let textColorFail = NSLocalizedString("color.wcag.fail", comment: "Fail")
    static let textColorRatio = NSLocalizedString("color.ratio", comment: "Contrast Ratio")
    static let textColorRatioDescription = NSLocalizedString("color.ratio.description", comment: "Contrast ratio is a measure of the difference in perceived brightness between two colors, used to calculate the contrast ratio.")
    static let textLightnessContrastValue = NSLocalizedString("color.lc", comment: "Lightness Contrast Level")
    static let textLightnessContrastValueDescription = NSLocalizedString("color.lc.description", comment: "Lightness contrast (Lc) is a measure of the lightness difference between two colors, used to calculate the contrast value.")
    static let textColorWCAG = NSLocalizedString("color.wcag", comment: "WCAG Compliance")
    static let textColorAPCA = NSLocalizedString("color.apca", comment: "APCA Compliance")
    static let textColorWCAG30 = NSLocalizedString("color.wcag.30", comment: "WCAG 3:1")
    static let textColorWCAG45 = NSLocalizedString("color.wcag.45", comment: "WCAG 4.5:1")
    static let textColorWCAG70 = NSLocalizedString("color.wcag.70", comment: "WCAG 7:1")
    static let textColorSwap = NSLocalizedString("color.swap", comment: "Swap")
    static let textColorSwapDetail = NSLocalizedString("color.swap.detail", comment: "Swap colors")
    static let textColorUndo = NSLocalizedString("color.undo", comment: "Undo")
    static let textColorRedo = NSLocalizedString("color.redo", comment: "Redo")
    static let textColorCopy = NSLocalizedString("color.copy", comment: "Copy")
    static let textColorSystemPicker = NSLocalizedString("color.system", comment: "System picker")
    static let textColorCopied = NSLocalizedString("color.copy.toast", comment: "Copied")

    /*
     * Menu
     */

    static let textMenuHelp = NSLocalizedString("menu.help", comment: "Help")
    static let textHelpDescription = NSLocalizedString("help.description", comment: "Help description")
    static let textHelpKeyboardShortcuts = NSLocalizedString("help.shortcuts", comment: "Keyboard Shortcuts")
    static let textHelpURLTriggers = NSLocalizedString("help.url_triggers", comment: "URL Triggers")
    static let textHelpURLTriggersDescription = NSLocalizedString("help.url_triggers.description", comment: "URL Triggers description")
    static let textHelpFormats = NSLocalizedString("help.formats", comment: "Formats")
    static let textHelpOpenSource = NSLocalizedString("help.open_source", comment: "Open Source")
    static let textHelpOpenSourceDescription = NSLocalizedString("help.open_source.description", comment: "Open Source description")
    static let textHelpViewOnGitHub = NSLocalizedString("help.github", comment: "View on GitHub")
    static let textHelpSupportOnMAS = NSLocalizedString("help.mas", comment: "Support on the Mac App Store")

    static let textMenuAbout = NSLocalizedString("menu.about", comment: "About")
    static let textMenuUpdates = NSLocalizedString("menu.updates", comment: "Check for updates")
    static let textMenuPreferences = NSLocalizedString("menu.preferences", comment: "Preferences")
    static let textMenuWebsite = NSLocalizedString("menu.website", comment: "Pika website")
    static let textMenuGitHubIssue = NSLocalizedString("menu.issue", comment: "Report feedback")
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
    static let textAboutMacAppStore = NSLocalizedString("app.store.mas", comment: "Mac App Store")
    static let textAboutDownloaded = NSLocalizedString("app.store.download", comment: "Downloaded from the internet")

    // APCA Compliance Labels
    static let textAPCABaseline = NSLocalizedString("color.apca.baseline", comment: "Baseline")
    static let textAPCAHeadline = NSLocalizedString("color.apca.headline", comment: "Headline")
    static let textAPCATitle = NSLocalizedString("color.apca.title", comment: "Title")
    static let textAPCABody = NSLocalizedString("color.apca.body", comment: "Body Text")

    // APCA Tooltips
    static let textColorAPCA30 = NSLocalizedString("color.apca.30", comment: "APCA ≥30")
    static let textColorAPCA45 = NSLocalizedString("color.apca.45", comment: "APCA ≥45")
    static let textColorAPCA60 = NSLocalizedString("color.apca.60", comment: "APCA ≥60")
    static let textColorAPCA75 = NSLocalizedString("color.apca.75", comment: "APCA ≥75")

    // History
    static let textHistoryTitle = NSLocalizedString("history.title", comment: "History")
    static let textHistoryToggle = NSLocalizedString("history.toggle", comment: "Toggle palettes")
    static let textColorPreviewToggle = NSLocalizedString("color.preview.toggle", comment: "Toggle color preview")
    static let textComplianceToggle = NSLocalizedString("compliance.toggle", comment: "Toggle compliance")
    static let textHistoryApplyForeground = NSLocalizedString("history.apply.foreground", comment: "Apply foreground only")
    static let textHistoryApplyBackground = NSLocalizedString("history.apply.background", comment: "Apply background only")
    static let textHistoryRemove = NSLocalizedString("history.remove", comment: "Remove from history")
    static let textHistoryClear = NSLocalizedString("history.clear", comment: "Clear history")

    // Palettes
    static let textPaletteNew = NSLocalizedString("palette.new", comment: "New palette…")
    static let textPaletteRename = NSLocalizedString("palette.rename", comment: "Rename palette")
    static let textPaletteDelete = NSLocalizedString("palette.delete", comment: "Delete palette")
    static let textPaletteRemoveChip = NSLocalizedString("palette.remove", comment: "Remove from palette")
    static let textPaletteNamePrompt = NSLocalizedString("palette.name.prompt", comment: "Palette name")
    static let textPaletteNamePlaceholder = NSLocalizedString("palette.name.placeholder", comment: "My palette")
    static let textPaletteAddColor = NSLocalizedString("palette.add", comment: "Add to palette")
    static let textPaletteExport = NSLocalizedString("palette.export", comment: "Export palette")
    static let textHistoryExport = NSLocalizedString("history.export", comment: "Export color history")
    static let textHistoryClearConfirm = NSLocalizedString("history.clear.confirm", comment: "Are you sure you want to clear all history?")

    // Keyboard shortcuts
    static let textPickForeground = NSLocalizedString("color.pick.foreground", comment: "Pick foreground")
    static let textPickBackground = NSLocalizedString("color.pick.background", comment: "Pick background")
    static let textCopyForeground = NSLocalizedString("color.copy.foreground", comment: "Copy foreground")
    static let textCopyBackground = NSLocalizedString("color.copy.background", comment: "Copy background")
    static let textColorSystemPickerForeground = NSLocalizedString(
        "color.system.foreground",
        comment: "Use foreground system color picker"
    )
    static let textColorSystemPickerBackground = NSLocalizedString(
        "color.system.background",
        comment: "Use background system color picker"
    )
    static let textColorSystemPickerForegroundSimple = NSLocalizedString(
        "color.system.foreground.simple",
        comment: "System foreground"
    )
    static let textColorSystemPickerBackgroundSimple = NSLocalizedString(
        "color.system.background.simple",
        comment: "System background"
    )

    /*
     * Preferences
     */

    // General Settings
    static let textGeneralTitle = NSLocalizedString("preferences.general.title", comment: "General Settings")
    static let textLaunchDescription = NSLocalizedString(
        "preferences.launch.description",
        comment: "Launch at login"
    )
    static let textBetaDescription = NSLocalizedString(
        "preferences.beta.description",
        comment: "Subscribe to beta releases"
    )
    static let textSelectionTitle = NSLocalizedString("preferences.selection.title", comment: "Selection Settings")
    static let textPickHide = NSLocalizedString("preferences.pick.hide", comment: "Hide Pika while picking")
    static let textIconDescription = NSLocalizedString(
        "preferences.icon.description",
        comment: "Hide menu bar icon"
    )
    static let textColorNamesDescription = NSLocalizedString(
        "preferences.names.description",
        comment: "Hide color names"
    )
    static let textFloatDescription = NSLocalizedString(
        "preferences.float.description",
        comment: "Float above windows"
    )
    static let textAlwaysShowOnLaunch = NSLocalizedString(
        "preferences.show.description",
        comment: "Always show Pika on launch"
    )

    // App Settings
    static let textAppTitle = NSLocalizedString("preferences.app.title", comment: "App Settings")
    static let textAppMenubarTitle = NSLocalizedString("preferences.app.menubar.title", comment: "Menu bar")
    static let textAppMenubarDescription = NSLocalizedString(
        "preferences.app.menubar.description", comment: "Show in menu bar"
    )
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
    static let textAppearanceAPCATitle = NSLocalizedString(
        "preferences.appearance.apca.title",
        comment: "Contrast Value"
    )
    static let textAppearanceAPCADescription = NSLocalizedString(
        "preferences.appearance.apca.description",
        comment: "View APCA contrast value by lightness contrast (Lc), from 30 to 75"
    )
    static let textContrastStandard = NSLocalizedString(
        "preferences.contrast.standard",
        comment: "Contrast Standard"
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

    static let textFormatHex = NSLocalizedString("color.format.hex", comment: "Hex format")
    static let textFormatRGB = NSLocalizedString("color.format.rgb", comment: "RGB format")
    static let textFormatHSL = NSLocalizedString("color.format.hsl", comment: "HSL format")
    static let textFormatHSB = NSLocalizedString("color.format.hsb", comment: "HSB format")
    static let textFormatOpenGL = NSLocalizedString("color.format.opengl", comment: "OpenGL format")
    static let textFormatLAB = NSLocalizedString("color.format.lab", comment: "LAB format")
    static let textFormatOKLCH = NSLocalizedString("color.format.oklch", comment: "OKLCH format")

    // Global Shortcut
    static let textHotkeyTitle = NSLocalizedString("preferences.hotkey.title", comment: "Global Shortcut")
    static let textHotkeyDescription = NSLocalizedString(
        "preferences.hotkey.description",
        comment: "Set a global hotkey shortcut to invoke Pika"
    )

    // Color Preview
    static let textShowColorPreview = NSLocalizedString(
        "preferences.preview.show",
        comment: "Show foreground color on background color"
    )

    // Color Overlay
    static let textShowColorOverlay = NSLocalizedString(
        "preferences.overlay.show",
        comment: "Show color overlay after picking"
    )
    static let textDuration = NSLocalizedString("preferences.overlay.duration", comment: "Duration:")

    // URL Trigger Group Titles
    static let textUrlGroupPick = NSLocalizedString("help.url.group.pick", comment: "Pick")
    static let textUrlGroupCopy = NSLocalizedString("help.url.group.copy", comment: "Copy")
    static let textUrlGroupChangeFormat = NSLocalizedString("help.url.group.change_format", comment: "Change Format")
    static let textUrlGroupActions = NSLocalizedString("help.url.group.actions", comment: "Actions")
    static let textUrlGroupSetColor = NSLocalizedString("help.url.group.set_color", comment: "Set Color")
    static let textUrlGroupHistory = NSLocalizedString("help.url.group.history", comment: "History")
    static let textUrlGroupWindow = NSLocalizedString("help.url.group.window", comment: "Window")
    static let textUrlGroupAppearance = NSLocalizedString("help.url.group.appearance", comment: "Appearance")
    static let textUrlGroupCompliance = NSLocalizedString("help.url.group.compliance", comment: "Compliance")
    static let textUrlGroupPreview = NSLocalizedString("help.url.group.preview", comment: "Preview")

    // URL Trigger Descriptions — Set Color
    static let textUrlSetForeground = NSLocalizedString("help.url.set.foreground", comment: "Set foreground color")
    static let textUrlSetBackground = NSLocalizedString("help.url.set.background", comment: "Set background color")

    // URL Trigger Descriptions — History
    static let textUrlHistoryShow = NSLocalizedString("help.url.history.show", comment: "Show the history drawer")
    static let textUrlHistoryHide = NSLocalizedString("help.url.history.hide", comment: "Hide the history drawer")
    static let textUrlHistoryToggle = NSLocalizedString("help.url.history.toggle", comment: "Toggle the history drawer")

    // URL Trigger Descriptions — Window
    static let textUrlWindowAbout = NSLocalizedString("help.url.window.about", comment: "Open the About window")
    static let textUrlWindowHelp = NSLocalizedString("help.url.window.help", comment: "Open the Help window")
    static let textUrlWindowPreferences = NSLocalizedString(
        "help.url.window.preferences",
        comment: "Open the Preferences window"
    )
    static let textUrlWindowResize = NSLocalizedString("help.url.window.resize", comment: "Resize window")

    // URL Trigger Descriptions — Compliance
    static let textUrlComplianceShow = NSLocalizedString("help.url.compliance.show", comment: "Show compliance")
    static let textUrlComplianceHide = NSLocalizedString("help.url.compliance.hide", comment: "Hide compliance")
    static let textUrlComplianceToggle = NSLocalizedString("help.url.compliance.toggle", comment: "Toggle compliance")

    // URL Trigger Descriptions — Preview
    static let textUrlPreviewShow = NSLocalizedString("help.url.preview.show", comment: "Show colour preview")
    static let textUrlPreviewHide = NSLocalizedString("help.url.preview.hide", comment: "Hide colour preview")
    static let textUrlPreviewToggle = NSLocalizedString("help.url.preview.toggle", comment: "Toggle colour preview")

    // URL Trigger Descriptions — Appearance
    static let textUrlAppearanceLight = NSLocalizedString("help.url.appearance.light", comment: "Force light appearance")
    static let textUrlAppearanceDark = NSLocalizedString("help.url.appearance.dark", comment: "Force dark appearance")
    static let textUrlAppearanceSystem = NSLocalizedString(
        "help.url.appearance.system",
        comment: "Restore system appearance"
    )
}

// swiftlint:enable line_length
// line_length is disabled above because NSLocalizedString comment strings on lines 100 and 102
// exceed 120 characters and cannot be shortened without losing meaning for localizers.
