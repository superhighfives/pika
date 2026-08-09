import Cocoa

// swiftlint:disable identifier_name
// identifier_name is disabled because color science math uses conventional single-letter
// variable names (x, y, z, l, a, b, c, h, L, C, H) that would be misleading if renamed.

private struct XYZComponents { let x, y, z: CGFloat }
struct LabComponents { let l, a, b: CGFloat }
struct OklchComponents { let l, c, h: CGFloat }

extension NSColor {
    // Shared linearization for sRGB components used by both LAB and OKLCH.
    private func linearizeSRGB(_ c: CGFloat) -> CGFloat {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    // Inverse of `linearizeSRGB`: gamma-encode a linear-light component, clamped to [0, 1].
    // Lab and OKLCH can express colours outside the sRGB gamut, so the clamp snaps those
    // to the nearest displayable channel value (see the round-trip note in the plan).
    private static func encodeSRGB(_ c: CGFloat) -> CGFloat {
        let clamped = Swift.min(Swift.max(c, 0), 1)
        let encoded = clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        return Swift.min(Swift.max(encoded, 0), 1)
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

        // %.5g strips trailing zeros but drops the decimal entirely for whole numbers,
        // so append ".0" when there is no decimal point (e.g. 0 → "0.0", 1 → "1.0").
        let red = { let s = String(format: "%.5g", RGB.r); return s.contains(".") ? s : "\(s).0" }()
        let green = { let s = String(format: "%.5g", RGB.g); return s.contains(".") ? s : "\(s).0" }()
        let blue = { let s = String(format: "%.5g", RGB.b); return s.contains(".") ? s : "\(s).0" }()

        switch style {
        case .css, .design, .swiftUI:
            return "rgba(\(red), \(green), \(blue), 1.0)"
        case .unformatted:
            return "\(red), \(green), \(blue), 1.0"
        }
    }

    /*
     * CIE-LAB
     */

    private func toXYZComponents() -> XYZComponents {
        let srgb = toRGBAComponents(in: .sRGB)
        let r_lin = linearizeSRGB(srgb.r)
        let g_lin = linearizeSRGB(srgb.g)
        let b_lin = linearizeSRGB(srgb.b)

        let x = r_lin * 0.4124564 + g_lin * 0.3575761 + b_lin * 0.1804375
        let y = r_lin * 0.2126729 + g_lin * 0.7151522 + b_lin * 0.0721750
        let z = r_lin * 0.0193339 + g_lin * 0.1191920 + b_lin * 0.9503041

        return XYZComponents(x: x, y: y, z: z)
    }

    func toLabComponents() -> LabComponents {
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

        return LabComponents(l: L_star, a: a_star, b: b_star)
    }

    func toLabString(style: CopyFormat = .css) -> String {
        let lab = toLabComponents()
        let l_str = (round(lab.l * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2)
        let a_str = (round(lab.a * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2)
        let b_str = (round(lab.b * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2)

        switch style {
        case .css:
            return "lab(\(l_str) \(a_str) \(b_str))"
        case .design, .swiftUI:
            return "lab(\(l_str), \(a_str), \(b_str))"
        case .unformatted:
            return "\(l_str), \(a_str), \(b_str)"
        }
    }

    /*
     * OKLCH
     */

    func toOklchComponents() -> OklchComponents {
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

        return OklchComponents(l: L, c: C, h: H)
    }

    func toOklchString(style: CopyFormat = .css) -> String {
        let oklch = toOklchComponents()
        let l_str = (round(oklch.l * 10000) / 100).strippedDecimalString(maxDecimalPlaces: 2)
        let c_str = (round(oklch.c * 10000) / 10000).strippedDecimalString(maxDecimalPlaces: 4)
        let h_str = (round(oklch.h * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2)

        switch style {
        case .css:
            return "oklch(\(l_str)% \(c_str) \(h_str))"
        case .design, .swiftUI:
            return "oklch(\(l_str), \(c_str), \(h_str))"
        case .unformatted:
            return "\(l_str), \(c_str), \(h_str)"
        }
    }

    /*
     * Inverses (component → colour)
     *
     * Inverses of `toLabComponents` / `toOklchComponents`, taking the same units the forward
     * conversions produce (Lab: L 0…100, a/b unbounded; OKLCH: L 0…1, C ≥ 0, H in degrees).
     * Both forward conversions are defined via the sRGB path, so these build in sRGB. Out-of-gamut
     * inputs are clamped per channel (see `encodeSRGB`), so a round-trip on an out-of-gamut colour
     * snaps to the nearest displayable one — inherent to storing sRGB.
     */

    /// Build an sRGB colour from CIE-Lab components (L in 0…100, a/b in Lab units).
    static func fromLab(l: CGFloat, a: CGFloat, b: CGFloat) -> NSColor {
        // Lab → XYZ (D65 reference white), inverse of the forward f().
        let Xn: CGFloat = 0.95047
        let Yn: CGFloat = 1.00000
        let Zn: CGFloat = 1.08883
        let delta: CGFloat = 6.0 / 29.0

        func fInv(_ t: CGFloat) -> CGFloat {
            t > delta ? pow(t, 3) : 3 * pow(delta, 2) * (t - 4.0 / 29.0)
        }

        let fy = (l + 16) / 116
        let fx = fy + a / 500
        let fz = fy - b / 200

        let x = Xn * fInv(fx)
        let y = Yn * fInv(fy)
        let z = Zn * fInv(fz)

        // XYZ → linear sRGB
        let r_lin = x * 3.2404542 - y * 1.5371385 - z * 0.4985314
        let g_lin = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
        let b_lin = x * 0.0556434 - y * 0.2040259 + z * 1.0572252

        return NSColor(
            colorSpace: .sRGB,
            components: [encodeSRGB(r_lin), encodeSRGB(g_lin), encodeSRGB(b_lin), 1],
            count: 4
        )
    }

    /// Build an sRGB colour from OKLCH components (L in 0…1, C ≥ 0, H in degrees).
    static func fromOklch(l: CGFloat, c: CGFloat, h: CGFloat) -> NSColor {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)

        // OKLCH → OKLab → LMS' → LMS (inverse of the forward M2/M1 matrices).
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let lCube = l_ * l_ * l_
        let mCube = m_ * m_ * m_
        let sCube = s_ * s_ * s_

        // LMS → linear sRGB
        let r_lin = lCube * 4.0767416621 - mCube * 3.3077115913 + sCube * 0.2309699292
        let g_lin = lCube * -1.2684380046 + mCube * 2.6097574011 - sCube * 0.3413193965
        let b_lin = lCube * -0.0041960863 - mCube * 0.7034186147 + sCube * 1.7076147010

        return NSColor(
            colorSpace: .sRGB,
            components: [encodeSRGB(r_lin), encodeSRGB(g_lin), encodeSRGB(b_lin), 1],
            count: 4
        )
    }
}

// swiftlint:enable identifier_name
