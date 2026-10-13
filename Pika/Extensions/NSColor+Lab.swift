import Cocoa

// swiftlint:disable identifier_name large_tuple
// identifier_name is disabled because color science math uses conventional single-letter
// variable names (x, y, z, l, a, b, c, h, L, C, H) that would be misleading if renamed.

private struct XYZComponents { let x, y, z: CGFloat }
struct LabComponents { let l, a, b: CGFloat }
struct OklchComponents { let l, c, h: CGFloat }

/// A 3×3 matrix applied to a colour triple.
private struct Matrix3 {
    let rows: [[CGFloat]]

    func apply(_ v0: CGFloat, _ v1: CGFloat, _ v2: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        (
            rows[0][0] * v0 + rows[0][1] * v1 + rows[0][2] * v2,
            rows[1][0] * v0 + rows[1][1] * v1 + rows[1][2] * v2,
            rows[2][0] * v0 + rows[2][1] * v1 + rows[2][2] * v2
        )
    }

    /// The inverse, computed rather than written out. The published inverse matrices are rounded
    /// independently of the forward ones, which is invisible inside sRGB but compounds outside
    /// it: an authored OKLCH chroma of 0.4 read back as much as 0.0003 off. Deriving one from the
    /// other makes a round trip exact to floating-point precision.
    var inverse: Matrix3 {
        let m = rows
        let c00 = m[1][1] * m[2][2] - m[1][2] * m[2][1]
        let c01 = m[1][2] * m[2][0] - m[1][0] * m[2][2]
        let c02 = m[1][0] * m[2][1] - m[1][1] * m[2][0]
        let det = m[0][0] * c00 + m[0][1] * c01 + m[0][2] * c02
        return Matrix3(rows: [
            [c00 / det, (m[0][2] * m[2][1] - m[0][1] * m[2][2]) / det, (m[0][1] * m[1][2] - m[0][2] * m[1][1]) / det],
            [c01 / det, (m[0][0] * m[2][2] - m[0][2] * m[2][0]) / det, (m[0][2] * m[1][0] - m[0][0] * m[1][2]) / det],
            [c02 / det, (m[0][1] * m[2][0] - m[0][0] * m[2][1]) / det, (m[0][0] * m[1][1] - m[0][1] * m[1][0]) / det],
        ])
    }
}

// Linear sRGB → XYZ (D65).
private let sRGBToXYZ = Matrix3(rows: [
    [0.4124564, 0.3575761, 0.1804375],
    [0.2126729, 0.7151522, 0.0721750],
    [0.0193339, 0.1191920, 0.9503041],
])
private let xyzToSRGB = sRGBToXYZ.inverse

// OKLab's M1 (linear sRGB → LMS) and M2 (cube-rooted LMS → Lab).
private let sRGBToLMS = Matrix3(rows: [
    [0.4122214708, 0.5363325363, 0.0514459929],
    [0.2119034982, 0.6806995451, 0.1073969566],
    [0.0883024619, 0.2817188376, 0.6299787005],
])
private let lmsToSRGB = sRGBToLMS.inverse
private let lmsToOklab = Matrix3(rows: [
    [0.2104542553, 0.7936177850, -0.0040720468],
    [1.9779984951, -2.4285922050, 0.4505937099],
    [0.0259040371, 0.7827717662, -0.8086757660],
])
private let oklabToLMS = lmsToOklab.inverse

extension NSColor {
    // Lab and OKLCH can express colours outside the sRGB gamut. Those are carried as extended
    // sRGB, whose components run below 0 and above 1, so nothing here clamps: the transfer
    // function is mirrored through zero for negative values, as extended sRGB defines it.
    // Clamping happens only where a format or the display genuinely can't hold the colour
    // (hex and RGB via `toRGBAComponents(in:)`, contrast via `luminance`).

    // Shared linearization for extended sRGB components used by both LAB and OKLCH.
    static func linearizeExtendedSRGB(_ c: CGFloat) -> CGFloat {
        let magnitude = abs(c)
        let linear = magnitude <= 0.04045 ? magnitude / 12.92 : pow((magnitude + 0.055) / 1.055, 2.4)
        return c < 0 ? -linear : linear
    }

    // Inverse of `linearizeExtendedSRGB`: gamma-encode a linear-light component, unclamped.
    static func encodeExtendedSRGB(_ c: CGFloat) -> CGFloat {
        let magnitude = abs(c)
        let encoded = magnitude <= 0.0031308 ? 12.92 * magnitude : 1.055 * pow(magnitude, 1 / 2.4) - 0.055
        return c < 0 ? -encoded : encoded
    }

    /// Linear-light extended sRGB components of this colour, unclamped.
    func toLinearExtendedSRGB() -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let rgb = toRGBAComponents(in: .extendedSRGB)
        return (
            Self.linearizeExtendedSRGB(rgb.r),
            Self.linearizeExtendedSRGB(rgb.g),
            Self.linearizeExtendedSRGB(rgb.b)
        )
    }

    /*
     * OpenGL
     */

    /**
     Get the RGB values of this color in OpenGL format.

     - returns: An NSColor as an OpenGL string.
     */
    func toOpenGLString(style: CopyFormat = .css) -> String {
        let RGB = toRGBAComponents()

        // `colorDecimalString` strips trailing zeros, dropping the decimal entirely for whole
        // numbers, so append ".0" when there is no decimal point (e.g. 0 → "0.0", 1 → "1.0").
        let red = { let s = RGB.r.colorDecimalString; return s.contains(".") ? s : "\(s).0" }()
        let green = { let s = RGB.g.colorDecimalString; return s.contains(".") ? s : "\(s).0" }()
        let blue = { let s = RGB.b.colorDecimalString; return s.contains(".") ? s : "\(s).0" }()

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
        let (r_lin, g_lin, b_lin) = toLinearExtendedSRGB()

        let (x, y, z) = sRGBToXYZ.apply(r_lin, g_lin, b_lin)

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
        let (r_lin, g_lin, b_lin) = toLinearExtendedSRGB()

        let (l, m, s) = sRGBToLMS.apply(r_lin, g_lin, b_lin)
        let (L, a, b) = lmsToOklab.apply(cbrt(l), cbrt(m), cbrt(s))

        let C = sqrt(a * a + b * b)
        var H = atan2(b, a) * 180.0 / .pi
        if H < 0 { H += 360.0 }
        // A hue of exactly 0 comes back as -1e-17 or so, which the line above turns into 360.
        // Report 0 whenever it would display as 360 (2 decimal places); they're the same hue.
        if H >= 359.995 { H = 0 }
        // With no chroma, hue is meaningless (CSS calls it powerless): atan2 of float noise gave
        // white a hue of 89.88. Report 0 whenever chroma would display as 0 (4 decimal places).
        if C < 0.00005 { H = 0 }

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
     * Both build in extended sRGB and don't clamp, so a value outside the sRGB gamut survives a
     * round trip through the forward conversion and renders as itself on a display that can show
     * it (see `isDisplayable(in:)` for telling when it can't).
     */

    /// Build an extended sRGB colour from CIE-Lab components (L in 0…100, a/b in Lab units).
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

        let (r_lin, g_lin, b_lin) = xyzToSRGB.apply(x, y, z)

        return NSColor(
            colorSpace: .extendedSRGB,
            components: [encodeExtendedSRGB(r_lin), encodeExtendedSRGB(g_lin), encodeExtendedSRGB(b_lin), 1],
            count: 4
        )
    }

    /// Build an extended sRGB colour from OKLCH components (L in 0…1, C ≥ 0, H in degrees).
    static func fromOklch(l: CGFloat, c: CGFloat, h: CGFloat) -> NSColor {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)

        // OKLCH → OKLab → LMS' → LMS → linear sRGB (inverses of the forward M2/M1 matrices).
        let (l_, m_, s_) = oklabToLMS.apply(l, a, b)
        let (r_lin, g_lin, b_lin) = lmsToSRGB.apply(l_ * l_ * l_, m_ * m_ * m_, s_ * s_ * s_)

        return NSColor(
            colorSpace: .extendedSRGB,
            components: [encodeExtendedSRGB(r_lin), encodeExtendedSRGB(g_lin), encodeExtendedSRGB(b_lin), 1],
            count: 4
        )
    }
}

// swiftlint:enable identifier_name large_tuple
