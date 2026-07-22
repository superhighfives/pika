import Foundation

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
    // swiftlint:disable:next line_length
    static let textColorRatioDescription = NSLocalizedString("color.ratio.description", comment: "Contrast ratio is a measure of the difference in perceived brightness between two colors, used to calculate the contrast ratio.")
    static let textLightnessContrastValue = NSLocalizedString("color.lc", comment: "Lightness Contrast Level")
    // swiftlint:disable:next line_length
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

    // Splash setup list (two-column redesign)
    static let textSplashSetupTitle = NSLocalizedString(
        "splash.setup.title", value: "Welcome to Pika", comment: "Splash setup heading"
    )
    static let textSplashSetupSubtitle = NSLocalizedString(
        "splash.setup.subtitle", value: "A few quick choices to get you started.",
        comment: "Splash setup subheading"
    )
    static let textSplashShortcutSubtitle = NSLocalizedString(
        "splash.shortcut.subtitle", value: "Show and hide Pika from anywhere",
        comment: "Global shortcut row subtitle"
    )
    static let textSplashPairSubtitle = NSLocalizedString(
        "splash.pair.subtitle", value: "Grab a foreground, then a background",
        comment: "Pick-pair shortcut row subtitle"
    )
    static let textSplashLaunchSubtitle = NSLocalizedString(
        "splash.launch.subtitle", value: "Open Pika when you log in",
        comment: "Launch at login row subtitle"
    )
    static let textSplashPickerRecommended = NSLocalizedString(
        "splash.picker.recommended", value: "Recommended", comment: "Custom picker recommended badge"
    )
    static let textSplashPickerPermission = NSLocalizedString(
        "splash.picker.permission", value: "Needs Screen Recording permission",
        comment: "Custom picker permission note"
    )
    static let textSplashPickerFallback = NSLocalizedString(
        "splash.picker.fallback", value: "Not now? You’ll use the Basic picker.",
        comment: "Pro picker declined fallback note"
    )
    static let textSplashFooter = NSLocalizedString(
        "splash.footer", value: "You can change all of this in Settings.",
        comment: "Splash footer note"
    )
    static let textSplashConfirmTitle = NSLocalizedString(
        "splash.confirm.title", value: "Use Pika’s Pro picker?",
        comment: "Get started confirmation title when the Basic picker is selected"
    )
    static let textSplashConfirmBody = NSLocalizedString(
        "splash.confirm.body",
        value: "The Pro picker shows the colour, its format, and live contrast right in the "
            + "loupe as you pick — a much nicer experience than the macOS sampler. "
            + "You can always switch later in Settings.",
        comment: "Get started confirmation body"
    )
    static let textSplashConfirmEnable = NSLocalizedString(
        "splash.confirm.enable", value: "Enable Pro Picker", comment: "Confirmation: enable Pro picker"
    )
    static let textSplashConfirmContinue = NSLocalizedString(
        "splash.confirm.continue", value: "Continue with Basic Picker",
        comment: "Confirmation: keep the Basic picker"
    )

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
    static let textPickContrast = NSLocalizedString(
        "color.pick.contrast",
        comment: "Pick foreground then background"
    )
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
    static let textPickContrasting = NSLocalizedString(
        "preferences.pick.contrasting",
        comment: "Pick a contrasting background color after the foreground"
    )
    static let textWindowShadow = NSLocalizedString(
        "preferences.shadow.description",
        comment: "Window shadow"
    )
    static let textWindowSettingsTitle = NSLocalizedString(
        "preferences.window.title",
        comment: "Window Settings"
    )
    static let textExpandToFit = NSLocalizedString(
        "content.expandToFit",
        comment: "Expand the window to fit hidden elements"
    )
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
    static let textAppMenubarPopoverTitle = NSLocalizedString(
        "preferences.app.menubarPopover.title",
        comment: "Popover"
    )
    static let textAppMenubarPopoverDescription = NSLocalizedString(
        "preferences.app.menubarPopover.description",
        comment: "Show as menu bar popover"
    )

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
    static let textUrlWindowSplash = NSLocalizedString("help.url.window.splash", comment: "Open the Splash window")
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

    /*
     * Custom colour picker
     */

    // Settings — picker style tiles
    static let textPickerStyleTitle = NSLocalizedString(
        "preferences.picker.title", value: "Colour Picker", comment: "Colour picker style section title"
    )
    static let textPickerSystemTitle = NSLocalizedString(
        "preferences.picker.system.title", value: "Basic picker", comment: "Basic picker tile title"
    )
    static let textPickerSystemDescription = NSLocalizedString(
        "preferences.picker.system.description", value: "macOS colour sampler", comment: "Basic picker tile subtitle"
    )
    static let textPickerCustomTitle = NSLocalizedString(
        "preferences.picker.custom.title", value: "Pro picker", comment: "Pro picker tile title"
    )
    static let textPickerCustomDescription = NSLocalizedString(
        "preferences.picker.custom.description",
        value: "Live contrast & format", comment: "Pro picker tile subtitle"
    )
    static let textPickerPairMode = NSLocalizedString(
        "preferences.picker.pair",
        value: "Pick a background straight after the foreground", comment: "Pair pick mode toggle"
    )
    static let textPickerPermissionNeeded = NSLocalizedString(
        "preferences.picker.permission",
        value: "Pika needs Screen Recording permission to sample pixels for the Pro picker.",
        comment: "Screen recording permission explanation"
    )
    static let textPickerRelaunchNote = NSLocalizedString(
        "preferences.picker.relaunch.note",
        value: "Allow Screen Recording for Pika in System Settings, then relaunch Pika to finish enabling the Pro picker.",
        comment: "Screen recording relaunch guidance"
    )
    static let textPickerRelaunchButton = NSLocalizedString(
        "preferences.picker.relaunch.button", value: "Relaunch Pika",
        comment: "Relaunch Pika button"
    )
    static let textPickerGrantButton = NSLocalizedString(
        "preferences.picker.grant.button", value: "Grant Permission",
        comment: "Grant Screen Recording permission button"
    )

    // Permission revoked alert
    static let textPickerCustomRevertedTitle = NSLocalizedString(
        "picker.reverted.title", value: "Switched to the Basic picker",
        comment: "Permission revoked alert title"
    )
    static let textPickerCustomRevertedBody = NSLocalizedString(
        "picker.reverted.body",
        value: "Pika’s Pro picker needs Screen Recording permission, which isn’t currently granted. "
            + "You can re-enable it in Settings once permission is allowed.",
        comment: "Permission revoked alert body"
    )

    // Loupe slot indicator
    static let textPickerLoupeForeground = NSLocalizedString(
        "picker.loupe.foreground", value: "Picking Foreground", comment: "Loupe slot indicator (foreground)"
    )
    static let textPickerLoupeBackground = NSLocalizedString(
        "picker.loupe.background", value: "Picking Background", comment: "Loupe slot indicator (background)"
    )

    // Splash picker choice
    static let textSplashPickerPrompt = NSLocalizedString(
        "splash.picker.prompt", value: "Colour picker", comment: "Splash picker choice label"
    )

    // Pick pair shortcut
    static let textPickPair = NSLocalizedString(
        "color.pick.pair", value: "Pick pair", comment: "Pick a foreground then background pair"
    )
}
