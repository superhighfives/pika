import AppKit
import Defaults
import SwiftUI

/// Curved text laid out along an arc. Each glyph is advanced by its measured width, so
/// proportional (SF Pro) and monospaced fonts both space evenly. `centerAngle` is measured
/// clockwise from the top (0 = 12 o'clock); set `flip` on the bottom half so glyphs stay
/// upright and read left-to-right.
struct CircularText: View {
    let text: String
    var radius: CGFloat
    var nsFont: NSFont
    var centerAngle: Double = 0
    var flip: Bool = false

    var body: some View {
        let chars = text.map { String($0) }
        let widths = chars.map { ($0 as NSString).size(withAttributes: [.font: nsFont]).width }
        let total = widths.reduce(0, +)
        var running: CGFloat = 0
        var centers: [CGFloat] = []
        for width in widths {
            centers.append(running + width / 2); running += width
        }

        return ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, character in
                let offset = centers[index] - total / 2
                let theta = centerAngle + (flip ? -1.0 : 1.0) * Double(offset / max(radius, 1))
                Text(character)
                    .font(Font(nsFont))
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

/// The loupe: a circular window of magnified pixels (the sampled centre pixel outlined) with
/// the live readouts wrapped around it. Two themes (see `LoupeTheme`):
/// - `.lens`: the rim is filled with the hovered colour and engraved, SF Pro, with the format
///   around the top and the slot + colour name around the bottom.
/// - `.badge`: two white rounded badges (rotated 45°) hug the inside edge — format on one,
///   slot + colour name on the other.
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
    private let lensFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    private let badgeFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)

    var body: some View {
        ZStack {
            switch theme {
            case .lens: lens
            case .badge: badge
            case .card: card
            }
        }
        .frame(width: Self.totalSize, height: Self.totalSize)
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
        // Fade to half over Pika's own windows: a cue that it won't pick there.
        .opacity(viewModel.isOverApp ? 0.15 : 1)
        .animation(.easeInOut(duration: 0.2), value: theme)
        .animation(.easeInOut(duration: 0.2), value: viewModel.comparison)
        .animation(.easeInOut(duration: 0.2), value: viewModel.target)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isOverApp)
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
        let textRadius = lensGlass / 2 + 16
        let rimWidth: CGFloat = 28
        let rimOuter = (textRadius + rimWidth / 2) * 2
        // Bottom half of the rim is the colour you're picking; the top half is the other
        // colour of the pair, so you can compare them side by side.
        let other = viewModel.comparison ?? viewModel.sampleColor
        let anim = Animation.easeInOut(duration: 0.15)
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
            CircularText(text: lensTopText, radius: textRadius,
                         nsFont: fittedFont(lensTopText, base: lensFont, radius: textRadius, maxArc: 0.9 * .pi))
                .foregroundStyle(adaptiveText(on: other))
                .animation(anim, value: other)
            CircularText(text: lensBottomText, radius: textRadius,
                         nsFont: fittedFont(lensBottomText, base: lensFont, radius: textRadius, maxArc: 0.9 * .pi),
                         centerAngle: .pi, flip: true)
                .foregroundStyle(adaptiveText(on: viewModel.sampleColor))
                .animation(anim, value: viewModel.sampleColor)
        }
    }

    /// White on dark colours, black on light ones, so the engraving stays legible on its half.
    private func adaptiveText(on color: NSColor) -> Color {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        let luminance = 0.2126 * srgb.redComponent + 0.7152 * srgb.greenComponent + 0.0722 * srgb.blueComponent
        return luminance < 0.55 ? .white : .black
    }

    // Each half shows its colour's value and name ("value · name"). Contrast now updates live
    // in the main window's footer instead of on the rim.
    private var lensTopText: String {
        let pair = viewModel.comparison ?? viewModel.sampleColor
        let name = viewModel.comparison != nil ? viewModel.comparisonName : viewModel.colorName
        return lensLabel(value: pair.toFormat(format: colorFormat, style: copyFormat), name: name)
    }

    private var lensBottomText: String {
        lensLabel(value: formatText, name: viewModel.colorName)
    }

    private func lensLabel(value: String, name: String) -> String {
        name.isEmpty ? value : "\(value) · \(name)"
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
            badgePill(badgeTopText, fill: viewModel.sampleColor, radius: badgeRadius,
                      centerAngle: .pi / 4, flip: false)
            badgePill(badgeBottomText, fill: viewModel.sampleColor, radius: badgeRadius,
                      centerAngle: bottomBadgeCenter, flip: true)
        }
    }

    /// The fitted font and band fraction for a badge label.
    private func badgeArc(_ text: String, radius: CGFloat) -> (font: NSFont, fraction: Double) {
        let pad: CGFloat = 18
        let padArc = Double(2 * pad / radius)
        let font = fittedFont(text, base: badgeFont, radius: radius, maxArc: 0.44 * 2 * .pi - padArc)
        let width = (text as NSString).size(withAttributes: [.font: font]).width
        let fraction = min(0.44, (Double(width / radius) + padArc) / (2 * .pi))
        return (font, fraction)
    }

    /// A rounded band filled with `fill` and engraved with curved text (auto-flipped for
    /// legibility), centred at `centerAngle` (clockwise from the top). The font shrinks to keep
    /// the text inside the band — the two pills are each capped to ~44% of the ring so they
    /// never collide and glyphs never overrun the rounded caps.
    private func badgePill(_ text: String, fill: NSColor, radius: CGFloat,
                           centerAngle: Double, flip: Bool) -> some View
    {
        let lineWidth = badgeLineWidth
        // The font shrinks to keep the text within ~44% of the ring (see `badgeArc`): that
        // caps the arc so the two pills never collide AND — combined with drawing the band
        // around the top (0.75) — keeps the trim range inside [0, 1].
        let (font, fraction) = badgeArc(text, radius: radius)
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
            CircularText(text: text, radius: radius, nsFont: font,
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
/// the pair side by side, each with its value; the picking colour also carries its name.
/// Contrast now updates live in the main window's footer rather than here.
struct LoupeReadoutCard: View {
    @ObservedObject var viewModel: LoupeViewModel
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat

    private let cardWidth: CGFloat = 248
    private let panelHeight: CGFloat = 60

    // A wide, short infographic: the two colours fill the card side by side, each engraved with
    // its own value.
    var body: some View {
        Group {
            if let comparison = viewModel.comparison {
                HStack(spacing: 0) {
                    panel(viewModel.sampleColor, name: viewModel.colorName)
                    panel(comparison, name: nil)
                }
            } else {
                panel(viewModel.sampleColor, name: viewModel.colorName)
            }
        }
        .frame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        // Match the disc: fade over Pika's own windows (won't pick there).
        .opacity(viewModel.isOverApp ? 0.15 : 1)
        // Crossfade the panels and reflow between single/pair layouts as the readout changes.
        .animation(.easeInOut(duration: 0.2), value: viewModel.sampleColor)
        .animation(.easeInOut(duration: 0.2), value: viewModel.comparison)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isOverApp)
    }

    /// One colour panel: filled with the colour, its value (and the picking colour's name)
    /// centred in the legible contrast colour.
    private func panel(_ color: NSColor, name: String?) -> some View {
        VStack(spacing: 2) {
            Text(color.toFormat(format: colorFormat, style: copyFormat))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
            if let name, !name.isEmpty {
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .opacity(0.75)
            }
        }
        .foregroundStyle(Color(nsColor: color.getUIColor()))
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: panelHeight)
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
