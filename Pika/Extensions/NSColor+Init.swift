import Cocoa

extension NSColor {
    // r, g, b, a are the public parameter labels for this init (NSColor(r:g:b:a:)) and cannot be renamed.
    // swiftlint:disable:next identifier_name
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        if (r > 1) || (g > 1) || (b > 1) {
            self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
        } else {
            self.init(red: r, green: g, blue: b, alpha: a)
        }
    }

    /**
     Create an NSColor with a string hex value.

     - parameter hex:     The hex color, i.e. "FF0072" or "#FF0072".
     - parameter alpha:   The opacity of the color, value between [0,1]. Optional. Default: 1
     */
    convenience init(hex: String, alpha: CGFloat = 1) {
        var hex = hex.replacingOccurrences(of: "#", with: "")

        guard hex.count == 3 || hex.count == 6 else {
            fatalError("Hex characters must be either 3 or 6 characters.")
        }

        if hex.count == 3 {
            let tmp = hex
            hex = ""
            for char in tmp {
                hex += String([char, char])
            }
        }

        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xFF) / 255
        let green = CGFloat((rgb >> 8) & 0xFF) / 255
        let blue = CGFloat(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
