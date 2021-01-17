import Cocoa
import Defaults

enum ColorFormatKeys: String, Codable, CaseIterable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsb = "HSB"
    case hsl = "HSL"
}

extension Defaults.Keys {
    static let colorFormat = Key<ColorFormatKeys>("colorFormat", default: .hex)
    static let viewedSplash = Key<Bool>("viewedSplash", default: false)
    static let colorSpace = NSSecureCodingKey<NSColorSpace>("colorSpace", default: NSColorSpace.deviceRGB)
}
