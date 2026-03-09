import Cocoa

// swiftlint:disable identifier_name

extension NSColor {
    // Shared linearization for sRGB components used by both LAB and OKLCH.
    private func linearizeSRGB(_ c: CGFloat) -> CGFloat {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    /*
     * OpenGL
     */

    /**
     Get the rgb values of this color in opengl format.

     - returns: An NSColor as an opengl string.
     */
    func toOpenGLString(style: CopyFormat = .css) -> String {
        let RGB = toRGBAComponents()

        let formatString: NSString
        switch style {
        case .css, .design, .swiftUI:
            formatString = "rgba(%.5g, %.5g, %.5g, 1.0)"
        case .unformatted:
            formatString = "%.5g, %.5g, %.5g, 1.0"
        }

        let openGLString = NSString(format: formatString, RGB.r, RGB.g, RGB.b)
        return openGLString as String
    }

    /*
     * CIE-LAB
     */

    private func toXYZComponents() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let srgb = toRGBAComponents(in: .sRGB)
        let r_lin = linearizeSRGB(srgb.r)
        let g_lin = linearizeSRGB(srgb.g)
        let b_lin = linearizeSRGB(srgb.b)

        let x = r_lin * 0.4124564 + g_lin * 0.3575761 + b_lin * 0.1804375
        let y = r_lin * 0.2126729 + g_lin * 0.7151522 + b_lin * 0.0721750
        let z = r_lin * 0.0193339 + g_lin * 0.1191920 + b_lin * 0.9503041

        return (x: x, y: y, z: z)
    }

    func toLabComponents() -> (l: CGFloat, a: CGFloat, b: CGFloat) {
        let xyz = toXYZComponents()

        // D65 Reference White
        let Xn: CGFloat = 0.95047
        let Yn: CGFloat = 1.00000
        let Zn: CGFloat = 1.08883

        func f(_ t: CGFloat) -> CGFloat {
            let delta: CGFloat = 6.0 / 29.0
            if t > pow(delta, 3.0) {
                return pow(t, 1.0 / 3.0)
            } else {
                return (t / (3.0 * pow(delta, 2.0))) + (4.0 / 29.0)
            }
        }

        let L_star = (116.0 * f(xyz.y / Yn)) - 16.0
        let a_star = 500.0 * (f(xyz.x / Xn) - f(xyz.y / Yn))
        let b_star = 200.0 * (f(xyz.y / Yn) - f(xyz.z / Zn))

        return (l: L_star, a: a_star, b: b_star)
    }

    func toLabString(style: CopyFormat) -> String {
        let lab = toLabComponents()
        let l_val = round(lab.l * 100) / 100
        let a_val = round(lab.a * 100) / 100
        let b_val = round(lab.b * 100) / 100

        switch style {
        case .css:
            return String(format: "lab(%.2f %.2f %.2f)", l_val, a_val, b_val)
        case .design, .swiftUI:
            return String(format: "lab(%.2f, %.2f, %.2f)", l_val, a_val, b_val)
        case .unformatted:
            return String(format: "%.2f,%.2f,%.2f", l_val, a_val, b_val)
        }
    }

    /*
     * OKLCH
     */

    func toOklchComponents() -> (l: CGFloat, c: CGFloat, h: CGFloat) {
        let srgb = toRGBAComponents(in: .sRGB)
        let r_lin = linearizeSRGB(srgb.r)
        let g_lin = linearizeSRGB(srgb.g)
        let b_lin = linearizeSRGB(srgb.b)

        let l = 0.4122214708 * r_lin + 0.5363325363 * g_lin + 0.0514459929 * b_lin
        let m = 0.2119034982 * r_lin + 0.6806995451 * g_lin + 0.1073969566 * b_lin
        let s = 0.0883024619 * r_lin + 0.2817188376 * g_lin + 0.6299787005 * b_lin

        let l_ = cbrt(l)
        let m_ = cbrt(m)
        let s_ = cbrt(s)

        let L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        let a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        let b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

        let C = sqrt(a * a + b * b)
        var H = atan2(b, a) * 180.0 / .pi
        if H < 0 { H += 360.0 }

        return (l: L, c: C, h: H)
    }

    func toOklchString(style: CopyFormat) -> String {
        let oklch = toOklchComponents()
        let l_val = round(oklch.l * 10000) / 100
        let c_val = round(oklch.c * 10000) / 10000
        let h_val = round(oklch.h * 100) / 100

        switch style {
        case .css:
            return String(format: "oklch(%.2f%% %.4f %.2f)", l_val, c_val, h_val)
        case .design, .swiftUI:
            return String(format: "oklch(%.2f, %.4f, %.2f)", l_val, c_val, h_val)
        case .unformatted:
            return String(format: "%.2f, %.4f, %.2f", l_val, c_val, h_val)
        }
    }
}

// swiftlint:enable identifier_name
