import AppKit
import Defaults
import SwiftUI

/// Curved text laid out along an arc. Each glyph is advanced by its measured width, so
/// proportional (SF Pro) and monospaced fonts both space evenly. `centerAngle` is measured
/// clockwise from the top (0 = 12 o'clock); set `flip` on the bottom half so glyphs stay
/// upright and read left-to-right.
struct CircularText: View {
    /// A run of text in one font; a label can mix fonts (e.g. mono value + sans name).
    struct Segment { let text: String; let font: NSFont }

    let segments: [Segment]
    var radius: CGFloat
    var centerAngle: Double = 0
    var flip: Bool = false

    init(segments: [Segment], radius: CGFloat, centerAngle: Double = 0, flip: Bool = false) {
        self.segments = segments
        self.radius = radius
        self.centerAngle = centerAngle
        self.flip = flip
    }

    init(text: String, radius: CGFloat, nsFont: NSFont, centerAngle: Double = 0, flip: Bool = false) {
        self.init(segments: [Segment(text: text, font: nsFont)],
                  radius: radius, centerAngle: centerAngle, flip: flip)
    }

    var body: some View {
        let glyphs: [(char: String, font: NSFont)] = segments.flatMap { seg in
            seg.text.map { (String($0), seg.font) }
        }
        let widths = glyphs.map { ($0.char as NSString).size(withAttributes: [.font: $0.font]).width }
        let total = widths.reduce(0, +)
        var running: CGFloat = 0
        var centers: [CGFloat] = []
        for width in widths {
            centers.append(running + width / 2); running += width
        }

        return ZStack {
            ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                let offset = centers[index] - total / 2
                let theta = centerAngle + (flip ? -1.0 : 1.0) * Double(offset / max(radius, 1))
                Text(glyph.char)
                    .font(Font(glyph.font))
                    .rotationEffect(.radians(flip ? theta + .pi : theta))
                    .offset(x: radius * sin(theta), y: -radius * cos(theta))
            }
        }
        // Pin to a symmetric frame centred on the arc origin. Without this the view's
        // intrinsic bounds hug only the glyphs (a partial arc sits off-centre), so a parent
        // ZStack re-centres that lopsided box and shifts the text off its band.
        .frame(width: radius * 2, height: radius * 2)
    }
}

/// Shrink `base` until `text`, laid along a circle of `radius`, spans at most `maxArc`
/// radians — so a curved label never overruns its band. Never grows the font; floors at a
/// legible size. Preserves the font's family/weight via its descriptor.
private func fittedFont(_ text: String, base: NSFont, radius: CGFloat, maxArc: Double) -> NSFont {
    let maxLength = CGFloat(maxArc) * radius
    let width = (text as NSString).size(withAttributes: [.font: base]).width
    guard width > maxLength, width > 0 else { return base }
    let size = max(7.5, base.pointSize * (maxLength / width))
    return NSFont(descriptor: base.fontDescriptor, size: size) ?? base
}

/// Like `fittedFont` but for a multi-font label: scales every part by the same factor so the
/// whole run fits `maxArc` while keeping the mono/sans mix. Below the 7.5pt floor, scaling alone
/// can't bound the run any further (e.g. a long colour name combined with a verbose format), so
/// any remaining overrun is ellipsized off the trailing segment rather than left to spill.
private func fittedSegments(_ parts: [(String, NSFont)], radius: CGFloat, maxArc: Double) -> [CircularText.Segment] {
    let maxLength = CGFloat(maxArc) * radius
    let total = parts.reduce(CGFloat.zero) { $0 + ($1.0 as NSString).size(withAttributes: [.font: $1.1]).width }
    let scale = (total > maxLength && total > 0) ? maxLength / total : 1
    let segments = parts.map { text, font -> CircularText.Segment in
        guard scale < 1 else { return CircularText.Segment(text: text, font: font) }
        let size = max(7.5, font.pointSize * scale)
        return CircularText.Segment(text: text, font: NSFont(descriptor: font.fontDescriptor, size: size) ?? font)
    }
    return truncateToFit(segments, maxLength: maxLength)
}

/// Ellipsizes segments from the end until the run's total width fits `maxLength`, for when
/// scaling has already floored and the text still overruns its arc.
private func truncateToFit(_ segments: [CircularText.Segment], maxLength: CGFloat) -> [CircularText.Segment] {
    func width(_ segs: [CircularText.Segment]) -> CGFloat {
        segs.reduce(0) { $0 + ($1.text as NSString).size(withAttributes: [.font: $1.font]).width }
    }
    var result = segments
    while width(result) > maxLength, let last = result.last {
        var text = last.text
        if text.hasSuffix("…") { text.removeLast() }
        guard !text.isEmpty else { result.removeLast(); continue }
        text.removeLast()
        result[result.count - 1] = CircularText.Segment(text: text + "…", font: last.font)
    }
    return result
}

/// The loupe: a circular window of magnified pixels (the sampled centre pixel outlined) with
/// the live readouts wrapped around it. Three themes (see `LoupeTheme`):
/// - `.lens`: the rim is filled with the hovered colour and engraved, SF Pro, with the format
///   around the top and the slot + colour name around the bottom.
/// - `.badge`: two white rounded badges (rotated 45°) hug the inside edge — format on one,
///   slot + colour name on the other.
/// - `.card`: a plain magnifier with no rim readouts; the format and slot + colour name sit in
///   a `LoupeReadoutCard` tucked beside the loupe circle instead.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
struct LoupeCircle: View {
    @ObservedObject var viewModel: LoupeViewModel
    /// Overrides the user's theme preference (previews only).
    var forcedTheme: LoupeTheme?
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @Default(.loupeTheme) private var themePreference
    @Environment(\.colorScheme) private var colorScheme

    private var theme: LoupeTheme { forcedTheme ?? themePreference }

    // Adapt to the system appearance: outline is black on light, white on dark; the badge is
    // the inverse (white on light, black on dark) with matching text.
    private var outlineColor: Color { colorScheme == .dark ? .white : .black }

    /// Fixed square side of the view (and its hosting panel), sized for the larger theme.
    static let totalSize: CGFloat = 240

    private let lensGlass: CGFloat = 150
    private let badgeGlass: CGFloat = 200
    /// Diameter of the plain magnifier used by the `.card` theme (the readout sits in a
    /// separate panel beside it). Exposed so the controller can compute the card's clearance.
    static let cardGlass: CGFloat = 140
    // Values are monospaced, colour names sans-serif (matching the card readout).
    private let lensValueFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
    private let lensNameFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    private let badgeValueFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
    private let badgeNameFont = NSFont.systemFont(ofSize: 10, weight: .semibold)

    var body: some View {
        ZStack {
            if viewModel.isOverApp {
                // Over Pika's own windows the picker won't sample; show a distinct frosted
                // "dismiss" disc instead of a faded picker so the intent is unambiguous.
                dismissIndicator
            } else {
                switch theme {
                case .lens: lens
                case .badge: badge
                case .card: card
                }
            }
        }
        .frame(width: Self.totalSize, height: Self.totalSize)
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
        .animation(.easeInOut(duration: 0.2), value: theme)
        .animation(.easeInOut(duration: 0.2), value: viewModel.comparison)
        .animation(.easeInOut(duration: 0.2), value: viewModel.target)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isOverApp)
    }

    /// Shown while the cursor is over one of Pika's own windows: a small liquid-glass disc with
    /// a dismiss glyph. Clicking here commits the current colours (i.e. dismisses the pick).
    private var dismissIndicator: some View {
        let size: CGFloat = 74
        let mark = Image(systemName: "xmark")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.secondary)
        return Group {
            // `glassEffect` isn't declared in SDKs older than Xcode 26 (CI's pinned Xcode
            // 16.3 among them) — `#available` alone doesn't help there, since the symbol
            // is missing at compile time, not just unsupported at runtime.
            #if compiler(>=6.2)
                if #available(macOS 26.0, *) {
                    mark.frame(width: size, height: size)
                        .glassEffect(.clear.interactive(), in: .circle)
                } else {
                    mark.frame(width: size, height: size)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                }
            #else
                mark.frame(width: size, height: size)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            #endif
        }
    }

    // MARK: - Card theme

    /// A plain magnifier disc on the cursor, in the style of the system sampler. The live
    /// readouts ride in a separate `LoupeCardPanel` tucked beside it (managed by the controller).
    private var card: some View {
        glass(diameter: Self.cardGlass)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 3)
                .frame(width: Self.cardGlass, height: Self.cardGlass))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.22), lineWidth: 1)
                .frame(width: Self.cardGlass - 3, height: Self.cardGlass - 3))
    }

    // MARK: - Lens theme

    private var lens: some View {
        let rimWidth: CGFloat = 28
        // Rim inner edge sits flush on the glass (no gap between magnifier and colour band).
        let textRadius = lensGlass / 2 + rimWidth / 2
        let rimOuter = (textRadius + rimWidth / 2) * 2
        // Bottom half of the rim is the colour you're picking; the top half is the other
        // colour of the pair, so you can compare them side by side.
        let other = viewModel.comparison ?? viewModel.sampleColor
        let anim = Animation.easeInOut(duration: 0.15)
        let pairName = viewModel.comparison != nil ? viewModel.comparisonName : viewModel.colorName
        let topSegments = fittedSegments(
            lensParts(value: other.toFormat(format: colorFormat, style: copyFormat), name: pairName),
            radius: textRadius, maxArc: 0.9 * .pi
        )
        let bottomSegments = fittedSegments(
            lensParts(value: formatText, name: viewModel.colorName),
            radius: textRadius, maxArc: 0.9 * .pi
        )
        return ZStack {
            Circle().trim(from: 0, to: 0.5)
                .stroke(Color(nsColor: viewModel.sampleColor), lineWidth: rimWidth)
                .frame(width: textRadius * 2, height: textRadius * 2)
                .animation(anim, value: viewModel.sampleColor)
            Circle().trim(from: 0.5, to: 1.0)
                .stroke(Color(nsColor: other), lineWidth: rimWidth)
                .frame(width: textRadius * 2, height: textRadius * 2)
                .animation(anim, value: other)
            // Outer hairline defining the rim's outside edge (mirrors the badge's outer ring),
            // so the rim reads as a crisp disc rather than fading into the backdrop.
            Circle()
                .strokeBorder(outlineColor.opacity(0.5), lineWidth: 1.5)
                .frame(width: rimOuter, height: rimOuter)
            glass(diameter: lensGlass)
            Circle()
                .strokeBorder(outlineColor.opacity(0.6), lineWidth: 2)
                .frame(width: lensGlass, height: lensGlass)
            // Each half carries its own colour's value + name: the pair on the top (other-colour)
            // half, the picking colour on the bottom half — coloured for legibility on its own
            // half, and shrunk to stay within its arc so long values (OKLCH) never spill over.
            CircularText(segments: topSegments, radius: textRadius)
                .foregroundStyle(adaptiveText(on: other))
                .animation(anim, value: other)
            CircularText(segments: bottomSegments, radius: textRadius, centerAngle: .pi, flip: true)
                .foregroundStyle(adaptiveText(on: viewModel.sampleColor))
                .animation(anim, value: viewModel.sampleColor)
        }
    }

    private func adaptiveText(on color: NSColor) -> Color { color.getUIColor() }

    // Each half shows its colour's value (monospaced) then name (sans), joined by " · ".
    // Contrast now updates live in the main window's footer instead of on the rim.
    private func lensParts(value: String, name: String) -> [(String, NSFont)] {
        var parts: [(String, NSFont)] = [(value, lensValueFont)]
        if !name.isEmpty { parts.append((" · \(name)", lensNameFont)) }
        return parts
    }

    // MARK: - Badge theme

    private let badgeLineWidth: CGFloat = 20
    private let bottomBadgeCenter = Double.pi + .pi / 4 // 7:30

    private var badge: some View {
        let badgeRadius = badgeGlass / 2 - 18
        // Both pills are the colour you're picking (value on top, name on the bottom); the pair
        // is shown as the outer ring, so the whole badge frames what you're comparing against.
        let pair = viewModel.comparison ?? viewModel.sampleColor
        return ZStack {
            glass(diameter: badgeGlass)
            Circle()
                .strokeBorder(Color(nsColor: pair), lineWidth: 3)
                .frame(width: badgeGlass, height: badgeGlass)
                .animation(.easeInOut(duration: 0.15), value: pair)
            // Value pill in mono, name pill in sans — matching the card readout.
            badgePill(badgeTopText, fill: viewModel.sampleColor, base: badgeValueFont,
                      radius: badgeRadius, centerAngle: .pi / 4, flip: false)
            badgePill(badgeBottomText, fill: viewModel.sampleColor, base: badgeNameFont,
                      radius: badgeRadius, centerAngle: bottomBadgeCenter, flip: true)
        }
    }

    /// The fitted font, band fraction, and (possibly ellipsized) text for a badge label. Below
    /// the font's 7.5pt floor, scaling alone can't bound the run any further, so any remaining
    /// overrun is ellipsized — same fallback as the lens theme's `fittedSegments`.
    private func badgeArc(_ text: String, base: NSFont, radius: CGFloat) -> (text: String, font: NSFont, fraction: Double) {
        let pad: CGFloat = 18
        let padArc = Double(2 * pad / radius)
        let maxArc = 0.44 * 2 * .pi - padArc
        let font = fittedFont(text, base: base, radius: radius, maxArc: maxArc)
        let maxLength = CGFloat(maxArc) * radius
        let fitted = truncateToFit([CircularText.Segment(text: text, font: font)], maxLength: maxLength)
            .first ?? CircularText.Segment(text: text, font: font)
        let width = (fitted.text as NSString).size(withAttributes: [.font: fitted.font]).width
        let fraction = min(0.44, (Double(width / radius) + padArc) / (2 * .pi))
        return (fitted.text, fitted.font, fraction)
    }

    /// A rounded band filled with `fill` and engraved with curved text (auto-flipped for
    /// legibility), centred at `centerAngle` (clockwise from the top). The font shrinks to keep
    /// the text inside the band — the two pills are each capped to ~44% of the ring so they
    /// never collide and glyphs never overrun the rounded caps.
    private func badgePill(_ text: String, fill: NSColor, base: NSFont, radius: CGFloat,
                           centerAngle: Double, flip: Bool) -> some View
    {
        let lineWidth = badgeLineWidth
        // The font shrinks to keep the text within ~44% of the ring (see `badgeArc`): that
        // caps the arc so the two pills never collide AND — combined with drawing the band
        // around the top (0.75) — keeps the trim range inside [0, 1].
        let (fittedText, font, fraction) = badgeArc(text, base: base, radius: radius)
        // The band is a trimmed circle centred on the top (0.75). `Circle().trim` CLAMPS to
        // [0, 1] rather than wrapping across the 3-o'clock seam, so a band whose range straddled
        // the seam would be silently truncated (the cause of text spilling past the cap). Anchor
        // it at the top where the range stays in-bounds, then rotate the finished band — and only
        // the band — to the pill's position. The curved text places each glyph independently, so
        // it needs no such trick.
        let half = fraction / 2
        return ZStack {
            ZStack {
                // Hairline edge one step wider than the fill: keeps the pill crisp even when its
                // colour matches the glass (the top pill over a solid-colour region would
                // otherwise vanish into the same-coloured disc).
                Circle()
                    .trim(from: 0.75 - half, to: 0.75 + half)
                    .stroke(outlineColor.opacity(0.5), style: StrokeStyle(lineWidth: lineWidth + 2, lineCap: .round))
                    .shadow(color: .black.opacity(0.25), radius: 2.5, y: 1)
                Circle()
                    .trim(from: 0.75 - half, to: 0.75 + half)
                    .stroke(Color(nsColor: fill), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.radians(centerAngle))
            CircularText(text: fittedText, radius: radius, nsFont: font,
                         centerAngle: centerAngle, flip: flip)
                .foregroundStyle(adaptiveText(on: fill))
        }
        // Grow/shrink the band and re-flow the glyphs smoothly as the readout changes, and
        // crossfade the fill as the colour changes.
        .animation(.easeInOut(duration: 0.15), value: text)
        .animation(.easeInOut(duration: 0.15), value: fill)
    }

    private var badgeTopText: String { formatText }

    // Just the colour name — contrast now updates live in the main window's footer.
    private var badgeBottomText: String { viewModel.colorName }

    // MARK: - Glass

    private func glass(diameter: CGFloat) -> some View {
        ZStack {
            Color(nsColor: viewModel.sampleColor)
            if let image = viewModel.image {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
            }
            centerCell(diameter: diameter)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    /// One magnified pixel cell, outlined, marking the sampled centre pixel.
    private func centerCell(diameter: CGFloat) -> some View {
        let cell = diameter / CGFloat(max(1, viewModel.pixelCount))
        return Rectangle()
            .strokeBorder(Color.white, lineWidth: 1)
            .frame(width: cell, height: cell)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.black, lineWidth: 1)
                    .padding(-1)
            )
    }

    // MARK: - Readouts

    private var formatText: String {
        viewModel.sampleColor.toFormat(format: colorFormat, style: copyFormat)
    }
}

/// The readout card tucked beside the loupe circle for the `.card` theme: the two colours of
/// the pair stacked, each full width with its value and name. Contrast now updates live in the
/// main window's footer rather than here.
struct LoupeReadoutCard: View {
    @ObservedObject var viewModel: LoupeViewModel
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat

    private let cardWidth: CGFloat = 240

    // Colours stacked so each gets the full width — plenty of room for the value and name.
    var body: some View {
        VStack(spacing: 0) {
            panel(viewModel.sampleColor, name: viewModel.colorName)
            if let comparison = viewModel.comparison {
                panel(comparison, name: viewModel.comparisonName)
            }
        }
        .frame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        // Hidden over Pika's own windows — the disc shows the dismiss indicator instead.
        .opacity(viewModel.isOverApp ? 0 : 1)
        // Crossfade the panels and reflow between single/pair layouts as the readout changes.
        .animation(.easeInOut(duration: 0.2), value: viewModel.sampleColor)
        .animation(.easeInOut(duration: 0.2), value: viewModel.comparison)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isOverApp)
    }

    /// One full-width colour panel: the colour fill, its value (monospaced) and name (sans),
    /// in the legible contrast colour.
    private func panel(_ color: NSColor, name: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(color.toFormat(format: colorFormat, style: copyFormat))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if !name.isEmpty {
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(Color(nsColor: color.getUIColor()))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(nsColor: color))
    }
}

#if DEBUG
    private func loupePreviewModel(sample: NSColor, comparison: NSColor?, name: String) -> LoupeViewModel {
        let model = LoupeViewModel()
        model.sampleColor = sample
        model.comparison = comparison
        model.colorName = name
        model.pixelCount = 15
        return model
    }

    #Preview("Lens") {
        LoupeCircle(
            viewModel: loupePreviewModel(sample: NSColor(hex: "e32c88"), comparison: .black, name: "Mystic Magenta"),
            forcedTheme: .lens
        )
        .padding(40)
        .background(Color(white: 0.6))
    }

    #Preview("Badge") {
        LoupeCircle(
            viewModel: loupePreviewModel(sample: NSColor(hex: "e32c88"), comparison: .black, name: "Mystic Magenta"),
            forcedTheme: .badge
        )
        .padding(40)
        .background(Color(white: 0.6))
    }

    #Preview("Card") {
        HStack(spacing: 14) {
            LoupeCircle(
                viewModel: loupePreviewModel(sample: NSColor(hex: "e32c88"), comparison: .black, name: "Mystic Magenta"),
                forcedTheme: .card
            )
            LoupeReadoutCard(
                viewModel: loupePreviewModel(sample: NSColor(hex: "e32c88"), comparison: .black, name: "Mystic Magenta")
            )
        }
        .padding(40)
        .background(Color(white: 0.6))
    }
#endif
