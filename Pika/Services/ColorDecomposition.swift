import Cocoa
import Defaults

// swiftlint:disable identifier_name
// identifier_name is disabled because colour-component math uses conventional single-letter
// names (r, g, b, h, s, l, a) that would be misleading if renamed.

/// How a single editable component is validated and parsed.
enum ComponentKind: Equatable {
    case hex // 3 or 6 hex digits
    case integer // whole number in `range`
    case decimal // decimal number in `range` (nil range = unbounded, e.g. Lab a/b)
}

/// One editable number (or hex string) inside a formatted colour value.
struct ColorComponent: Equatable {
    var value: String
    var kind: ComponentKind
    var range: ClosedRange<Double>?

    /// Whether `candidate` is a valid value for this component's kind and range.
    /// This is what the editable field uses to drive its valid/invalid state.
    func isValid(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        switch kind {
        case .hex:
            return NSColor.fromHex(trimmed) != nil
        case .integer:
            // Reject decimals/exponents for integer fields; only a plain whole number. A
            // number outside `range` is still valid input, not rejected — it's clamped to the
            // nearest bound on commit (see `EditableColorValue.clampValuesToRange`), matching
            // `recompose`'s own clamping rather than reverting the whole edit.
            return Int(trimmed) != nil
        case .decimal:
            // `Double("inf")`/`Double("nan")` parse successfully but aren't valid colour
            // values, and a nil range (e.g. Lab a/b) wouldn't otherwise reject them. As with
            // `.integer`, a finite out-of-range number is valid input — clamped on commit.
            guard let n = Double(trimmed) else { return false }
            return n.isFinite
        }
    }
}

/// A formatted colour value split into fixed scaffolding + editable components.
///
/// Invariant: `joined()` equals `color.toFormat(format:style:)` for the colour it was
/// decomposed from — the editable readout renders the same text as the read-only one.
struct DecomposedColor: Equatable {
    var leading: String
    var components: [ColorComponent]
    var separators: [String] // between components; count == components.count - 1
    var trailing: String

    var values: [String] { components.map(\.value) }

    func joined() -> String {
        var result = leading
        for (i, comp) in components.enumerated() {
            result += comp.value
            if i < separators.count { result += separators[i] }
        }
        return result + trailing
    }
}

extension ColorFormat {
    /// Split a colour into fixed scaffolding + editable components for `(self, style)`.
    /// Mirrors the matching `to…String` formatter exactly (see `joined()` invariant).
    func decompose(_ color: NSColor, style: CopyFormat, in cs: NSColorSpace) -> DecomposedColor {
        switch self {
        case .hex:
            let digits = String(format: "%06x", color.toHex(in: cs))
            return DecomposedColor(
                leading: style == .css ? "#" : "",
                components: [ColorComponent(value: digits, kind: .hex, range: nil)],
                separators: [],
                trailing: ""
            )

        case .rgb:
            let rgb = color.toRGBAComponents(in: cs)
            switch style {
            case .swiftUI:
                return DecomposedColor(
                    leading: "Color(red: ",
                    components: floatComponents([rgb.r, rgb.g, rgb.b], range: 0 ... 1),
                    separators: [", green: ", ", blue: "],
                    trailing: ")"
                )
            default:
                let comps = int255Components([rgb.r, rgb.g, rgb.b])
                return DecomposedColor(
                    leading: style == .unformatted ? "" : "rgb(",
                    components: comps,
                    separators: [", ", ", "],
                    trailing: style == .unformatted ? "" : ")"
                )
            }

        case .opengl:
            let rgb = color.toRGBAComponents(in: cs)
            let comps = [rgb.r, rgb.g, rgb.b].map {
                ColorComponent(value: openGLValueString($0), kind: .decimal, range: 0 ... 1)
            }
            return DecomposedColor(
                leading: style == .unformatted ? "" : "rgba(",
                components: comps,
                separators: [", ", ", "],
                trailing: style == .unformatted ? ", 1.0" : ", 1.0)"
            )

        case .hsb:
            let hsb = color.toHSBComponents()
            switch style {
            case .swiftUI:
                return DecomposedColor(
                    leading: "Color(hue: ",
                    components: floatComponents([hsb.h, hsb.s, hsb.b], range: 0 ... 1),
                    separators: [", saturation: ", ", brightness: "],
                    trailing: ")"
                )
            case .css:
                return DecomposedColor(
                    leading: "hsb(",
                    components: angleAndPercents(h: hsb.h, [hsb.s, hsb.b]),
                    separators: [", ", "%, "],
                    trailing: "%)"
                )
            default:
                return DecomposedColor(
                    leading: style == .unformatted ? "" : "hsb(",
                    components: angleAndPercents(h: hsb.h, [hsb.s, hsb.b]),
                    separators: [", ", ", "],
                    trailing: style == .unformatted ? "" : ")"
                )
            }

        case .hsl:
            let hsl = color.toHSLComponents()
            let comps = angleAndPercents(h: hsl.h, [hsl.s, hsl.l])
            switch style {
            case .css:
                return DecomposedColor(
                    leading: "hsl(", components: comps, separators: [", ", "%, "], trailing: "%)"
                )
            case .unformatted:
                return DecomposedColor(
                    leading: "", components: comps, separators: [", ", ", "], trailing: ""
                )
            default: // design, swiftUI both render "hsl(%d, %d, %d)"
                return DecomposedColor(
                    leading: "hsl(", components: comps, separators: [", ", ", "], trailing: ")"
                )
            }

        case .lab:
            let lab = color.toLabComponents()
            let comps = [
                labComponent(lab.l, range: 0 ... 100),
                labComponent(lab.a, range: nil),
                labComponent(lab.b, range: nil),
            ]
            switch style {
            case .css:
                return DecomposedColor(
                    leading: "lab(", components: comps, separators: [" ", " "], trailing: ")"
                )
            case .unformatted:
                return DecomposedColor(
                    leading: "", components: comps, separators: [", ", ", "], trailing: ""
                )
            default:
                return DecomposedColor(
                    leading: "lab(", components: comps, separators: [", ", ", "], trailing: ")"
                )
            }

        case .oklch:
            let oklch = color.toOklchComponents()
            // L is shown as a 0–100 percentage-magnitude in every style; only css appends "%".
            let comps = [
                ColorComponent(
                    value: (round(oklch.l * 10000) / 100).strippedDecimalString(maxDecimalPlaces: 2),
                    kind: .decimal, range: 0 ... 100
                ),
                ColorComponent(
                    value: (round(oklch.c * 10000) / 10000).strippedDecimalString(maxDecimalPlaces: 4),
                    kind: .decimal, range: 0 ... 1
                ),
                ColorComponent(
                    value: (round(oklch.h * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2),
                    kind: .decimal, range: 0 ... 360
                ),
            ]
            switch style {
            case .css:
                return DecomposedColor(
                    leading: "oklch(", components: comps, separators: ["% ", " "], trailing: ")"
                )
            case .unformatted:
                return DecomposedColor(
                    leading: "", components: comps, separators: [", ", ", "], trailing: ""
                )
            default:
                return DecomposedColor(
                    leading: "oklch(", components: comps, separators: [", ", ", "], trailing: ")"
                )
            }
        }
    }

    /// Rebuild an sRGB-normalisable colour from edited component strings, or `nil` if any is
    /// unparseable. Assumes per-component validity has already been checked by the field; still
    /// clamps into range so a committed colour is always displayable.
    func recompose(_ values: [String], style: CopyFormat, in cs: NSColorSpace) -> NSColor? {
        switch self {
        case .hex:
            guard values.count == 1 else { return nil }
            return NSColor.fromHex(values[0], in: cs)

        case .rgb:
            guard let triple = doubles(values, count: 3) else { return nil }
            let rgb: [CGFloat]
            if style == .swiftUI {
                rgb = triple.map { clamp($0, 0, 1) }
            } else {
                rgb = triple.map { clamp($0, 0, 255) / 255 }
            }
            return NSColor(colorSpace: cs, components: rgb + [1], count: 4)

        case .opengl:
            guard let triple = doubles(values, count: 3) else { return nil }
            let rgb = triple.map { clamp($0, 0, 1) }
            return NSColor(colorSpace: cs, components: rgb + [1], count: 4)

        case .hsb:
            guard let triple = doubles(values, count: 3) else { return nil }
            let (h, s, b): (CGFloat, CGFloat, CGFloat)
            if style == .swiftUI {
                (h, s, b) = (clamp(triple[0], 0, 1), clamp(triple[1], 0, 1), clamp(triple[2], 0, 1))
            } else {
                (h, s, b) = (clamp(triple[0], 0, 360) / 360, clamp(triple[1], 0, 100) / 100, clamp(triple[2], 0, 100) / 100)
            }
            return NSColor.fromHSB(h: h, s: s, b: b, in: cs)

        case .hsl:
            guard let triple = doubles(values, count: 3) else { return nil }
            let h = clamp(triple[0], 0, 360) / 360
            let s = clamp(triple[1], 0, 100) / 100
            let l = clamp(triple[2], 0, 100) / 100
            return NSColor.fromHSL(h: h, s: s, l: l, in: cs)

        case .lab:
            guard let triple = doubles(values, count: 3) else { return nil }
            return NSColor.fromLab(l: triple[0], a: triple[1], b: triple[2])

        case .oklch:
            guard let triple = doubles(values, count: 3) else { return nil }
            return NSColor.fromOklch(l: triple[0] / 100, c: triple[1], h: triple[2])
        }
    }
}

// MARK: - Private formatting/parsing helpers

private func int255Components(_ channels: [CGFloat]) -> [ColorComponent] {
    channels.map { ColorComponent(value: String(Int(round($0 * 255))), kind: .integer, range: 0 ... 255) }
}

private func floatComponents(_ channels: [CGFloat], range: ClosedRange<Double>) -> [ColorComponent] {
    channels.map { ColorComponent(value: String(format: "%.5g", $0), kind: .decimal, range: range) }
}

/// Hue (0–360 integer) followed by two 0–100 integer percentages (S/B or S/L).
private func angleAndPercents(h: CGFloat, _ rest: [CGFloat]) -> [ColorComponent] {
    let hue = ColorComponent(value: String(Int(round(h * 360))), kind: .integer, range: 0 ... 360)
    let percents = rest.map {
        ColorComponent(value: String(Int(round($0 * 100))), kind: .integer, range: 0 ... 100)
    }
    return [hue] + percents
}

/// Matches `toOpenGLString`'s ".0"-appended `%.5g`, e.g. 0 → "0.0", 1 → "1.0", 0.5 → "0.5".
private func openGLValueString(_ value: CGFloat) -> String {
    let s = String(format: "%.5g", value)
    return s.contains(".") ? s : "\(s).0"
}

private func labComponent(_ value: CGFloat, range: ClosedRange<Double>?) -> ColorComponent {
    ColorComponent(
        value: (round(value * 100) / 100).strippedDecimalString(maxDecimalPlaces: 2),
        kind: .decimal, range: range
    )
}

private func doubles(_ values: [String], count: Int) -> [CGFloat]? {
    guard values.count == count else { return nil }
    var out: [CGFloat] = []
    for v in values {
        guard let d = Double(v.trimmingCharacters(in: .whitespaces)) else { return nil }
        out.append(CGFloat(d))
    }
    return out
}

private func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
    Swift.min(Swift.max(value, lower), upper)
}

// swiftlint:enable identifier_name
