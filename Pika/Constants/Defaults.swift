import Cocoa
import Defaults
import SwiftUI

enum ColorFormat: String, Codable, CaseIterable, Equatable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsb = "HSB"
    case hsl = "HSL"
    case lab = "LAB"
    case opengl = "OpenGL"
    case oklch = "OKLCH"

    func getExample(color: NSColor, style: CopyFormat) -> String {
        color.toFormat(format: self, style: style)
    }

    static func withLabel(_ label: String) -> ColorFormat? {
        allCases.first { label == "\($0)" }
    }
}

enum CopyFormat: String, Codable, CaseIterable {
    case css = "preferences.copy.options.css"
    case design = "preferences.copy.options.design"
    case swiftUI = "preferences.copy.options.swiftui"
    case unformatted = "preferences.copy.options.unformatted"

    func localizedString() -> String {
        NSLocalizedString(rawValue, comment: "Copy Format")
    }
}

enum ContrastStandard: String, Codable, CaseIterable {
    case wcag = "WCAG"
    case apca = "APCA"
    case both = "BOTH"

    func localizedString() -> String {
        switch self {
        case .wcag, .apca:
            return rawValue
        case .both:
            return NSLocalizedString("color.standard.both", comment: "Both")
        }
    }
}

enum WindowShadow: String, Codable, CaseIterable {
    case always = "preferences.shadow.options.always"
    case hiddenWhilePicking = "preferences.shadow.options.hiddenWhilePicking"
    case never = "preferences.shadow.options.never"

    func localizedString() -> String {
        NSLocalizedString(rawValue, comment: "Window Shadow")
    }

    /// The window's resting shadow state. `.hiddenWhilePicking` keeps the shadow at
    /// rest and only drops it during an active pick (handled by the picker).
    var showsShadowAtRest: Bool { self != .never }
}

enum PickerStyle: String, Codable, CaseIterable, Equatable {
    case system // NSColorSampler (default, today's behaviour)
    case custom // Pika-native loupe
}

enum PickMode: String, Codable, CaseIterable, Equatable {
    case single // one pick per trigger (default)
    case pair // trigger picks foreground, then chains to background
}

enum AppMode: String, Codable, CaseIterable {
    case menubar = "preferences.app.mode.menubar"
    case regular = "preferences.app.mode.regular"
    case hidden = "preferences.app.mode.hidden"
    case menubarPopover = "preferences.app.mode.menubarPopover"

    func localizedString() -> String {
        NSLocalizedString(rawValue, comment: "App Mode")
    }

    var activationPolicy: NSApplication.ActivationPolicy {
        switch self {
        case .regular: return .regular
        case .menubar, .menubarPopover, .hidden: return .accessory
        }
    }

    var usesStatusBarItem: Bool { self == .menubar || self == .menubarPopover }
    var usesPopover: Bool { self == .menubarPopover }
}

extension Defaults.Keys {
    static let colorFormat = Key<ColorFormat>("colorFormat", default: .hex)
    static let viewedSplash = Key<Bool>("viewedSplash", default: false)
    static let hidePikaWhilePicking = Key<Bool>("hidePikaWhilePicking", default: false)
    static let windowShadow = Key<WindowShadow>("windowShadow", default: .always)
    static let pickContrastingColor = Key<Bool>("pickContrastingColor", default: false)
    static let pickerStyle = Key<PickerStyle>("pickerStyle", default: .system)
    static let pickMode = Key<PickMode>("pickMode", default: .single)
    static let copyColorOnPick = Key<Bool>("copyColorOnPick", default: false)
    static let hideMenuBarIcon = Key<Bool>("hideMenuBarIcon", default: false)
    static let betaUpdates = Key<Bool>("betaUpdates", default: false)
    static let combineCompliance = Key<Bool>("combineCompliance", default: false)
    static let colorSpace = NSSecureCodingKey<NSColorSpace>(
        "colorSpace", default: NSScreen.main!.colorSpace!
    )
    static let hideColorNames = Key<Bool>("hideColorNames", default: false)
    static let formatColorsForCSS = Key<Bool>("formatColorsForCSS", default: false)
    static let copyFormat = Key<CopyFormat>("copyFormat", default: .css)
    static let appMode = Key<AppMode>("appMode", default: .menubar)
    static let appFloating = Key<Bool>("appFloating", default: true)
    static let alwaysShowOnLaunch = Key<Bool>("alwaysShowOnLaunch", default: false)
    static let contrastStandard = Key<ContrastStandard>("contrastStandard", default: .wcag)
    static let showColorOverlay = Key<Bool>("showColorOverlay", default: true)
    static let colorOverlayDuration = Key<Double>("colorOverlayDuration", default: 2.0)
    static let colorHistory = Key<[ColorPair]>("colorHistory", default: [])
    static let palettes = Key<[Palette]>("palettes", default: [
        Palette(id: UUID(), name: nil, pairs: [], createdAt: Date()),
    ])
    static let activePaletteIndex = Key<Int>("activePaletteIndex", default: 0)
    static let undoStack = Key<[[ColorPair]]>("undoStack", default: [])
    static let redoStack = Key<[[ColorPair]]>("redoStack", default: [])
    static let historyDrawerVisible = Key<Bool>("historyDrawerVisible", default: false)
    static let showColorPreview = Key<Bool>("showColorPreview", default: false)
    static let showCompliance = Key<Bool>("showCompliance", default: true)
}
