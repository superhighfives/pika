import Cocoa
import Defaults
import SwiftUI

enum ColorFormat: String, Codable, CaseIterable, Equatable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsb = "HSB"
    case hsl = "HSL"

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
    case unformatted = "preferences.copy.options.unformatted"

    func localizedString() -> String {
        NSLocalizedString(rawValue, comment: "Copy Format")
    }
}

enum AppMode: String, Codable, CaseIterable {
    case menubar = "preferences.app.mode.menubar"
    case regular = "preferences.app.mode.regular"
    case hidden = "preferences.app.mode.hidden"

    func localizedString() -> String {
        NSLocalizedString(rawValue, comment: "App Mode")
    }
}

extension Defaults.Keys {
    static let colorFormat = Key<ColorFormat>("colorFormat", default: .hex)
    static let viewedSplash = Key<Bool>("viewedSplash", default: false)
    static let hidePikaWhilePicking = Key<Bool>("hidePikaWhilePicking", default: false)
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
}
