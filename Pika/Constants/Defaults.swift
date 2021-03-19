import Cocoa
import Defaults

enum ColorFormat: String, Codable, CaseIterable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsb = "HSB"
    case hsl = "HSL"
}

extension Defaults.Keys {
    static let colorFormat = Key<ColorFormat>("colorFormat", default: .hex)
    static let viewedSplash = Key<Bool>("viewedSplash", default: false)
    static let hidePikaWhilePicking = Key<Bool>("hidePikaWhilePicking", default: false)
    static let hideMenuBarIcon = Key<Bool>("hideMenuBarIcon", default: false)
    static let betaUpdates = Key<Bool>("betaUpdates", default: false)
    static let colorSpace = NSSecureCodingKey<NSColorSpace>(
        "colorSpace", default: NSColorSpace.sRGB
    )
    static let hideColorNames = Key<Bool>("hideColorNames", default: false)
}
