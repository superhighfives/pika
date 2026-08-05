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
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @Default(.contrastStandard) private var contrastStandard
    @Default(.loupeTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // Adapt to the system appearance: outline is black on light, white on dark; the badge is
    // the inverse (white on light, black on dark) with matching text.
    private var outlineColor: Color { colorScheme == .dark ? .white : .black }
    private var badgeFill: Color { colorScheme == .dark ? .black : .white }
    private var badgeTextColor: Color { (colorScheme == .dark ? Color.white : Color.black).opacity(0.85) }

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
        .animation(.easeInOut(duration: 0.2), value: theme)
        .animation(.easeInOut(duration: 0.2), value: viewModel.comparison)
        .animation(.easeInOut(duration: 0.2), value: viewModel.target)
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
        // Bottom half of the rim is the colour you're picking; the top half is the other
        // colour of the pair, so you can compare them side by side.
        let other = viewModel.comparison ?? viewModel.sampleColor
        return ZStack {
            Circle().trim(from: 0, to: 0.5)
                .stroke(Color(nsColor: viewModel.sampleColor), lineWidth: 28)
                .frame(width: textRadius * 2, height: textRadius * 2)
            Circle().trim(from: 0.5, to: 1.0)
                .stroke(Color(nsColor: other), lineWidth: 28)
                .frame(width: textRadius * 2, height: textRadius * 2)
            glass(diameter: lensGlass)
            Circle()
                .strokeBorder(outlineColor.opacity(0.6), lineWidth: 2)
                .frame(width: lensGlass, height: lensGlass)
            // Format engraved on the top (other-colour) half; slot/name/contrast on the
            // bottom (picking-colour) half — each coloured for legibility on its own half.
            CircularText(text: formatText, radius: textRadius, nsFont: lensFont)
                .foregroundStyle(adaptiveText(on: other))
            CircularText(text: lensBottomText, radius: textRadius, nsFont: lensFont,
                         centerAngle: .pi, flip: true)
                .foregroundStyle(adaptiveText(on: viewModel.sampleColor))
        }
    }

    /// White on dark colours, black on light ones, so the engraving stays legible on its half.
    private func adaptiveText(on color: NSColor) -> Color {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        let luminance = 0.2126 * srgb.redComponent + 0.7152 * srgb.greenComponent + 0.0722 * srgb.blueComponent
        return luminance < 0.55 ? .white : .black
    }

    private var lensBottomText: String {
        var parts = [slotLabel]
        if !viewModel.colorName.isEmpty { parts.append(viewModel.colorName) }
        if let contrast = contrastLabel { parts.append(contrast) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Badge theme

    private var badge: some View {
        let badgeRadius = badgeGlass / 2 - 18
        return ZStack {
            glass(diameter: badgeGlass)
            Circle()
                .strokeBorder(outlineColor.opacity(0.85), lineWidth: 3)
                .frame(width: badgeGlass, height: badgeGlass)
            // Rotated 45°: top badge at 1:30, bottom badge at 7:30.
            badgePill(badgeTopText, radius: badgeRadius, centerAngle: .pi / 4, flip: false)
            badgePill(badgeBottomText, radius: badgeRadius, centerAngle: .pi + .pi / 4, flip: true)
        }
    }

    /// A white rounded band (the badge) with dark curved text engraved on it, centred at
    /// `centerAngle` (clockwise from the top).
    private func badgePill(_ text: String, radius: CGFloat, centerAngle: Double, flip: Bool) -> some View {
        let width = text.reduce(CGFloat.zero) { $0 + (String($1) as NSString).size(withAttributes: [.font: badgeFont]).width }
        let arc = Double(width / radius) + 0.45 // text arc + rounded-cap padding
        let fraction = min(0.95, arc / (2 * .pi))
        // Circle().trim starts at 3 o'clock and runs clockwise, so the top (12 o'clock) is
        // 0.75; convert the clockwise-from-top centre angle to that space.
        let centre = (0.75 + centerAngle / (2 * .pi)).truncatingRemainder(dividingBy: 1)
        return ZStack {
            Circle()
                .trim(from: centre - fraction / 2, to: centre + fraction / 2)
                .stroke(badgeFill, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
            CircularText(text: text, radius: radius, nsFont: badgeFont,
                         centerAngle: centerAngle, flip: flip)
                .foregroundStyle(badgeTextColor)
        }
        // Grow/shrink the band and re-flow the glyphs smoothly as the readout changes.
        .animation(.easeInOut(duration: 0.15), value: text)
    }

    private var badgeTopText: String { formatText.uppercased() }

    private var badgeBottomText: String {
        var parts = [slotLabel.uppercased()]
        if !viewModel.colorName.isEmpty { parts.append(viewModel.colorName.uppercased()) }
        if let contrast = contrastLabel { parts.append(contrast) }
        return parts.joined(separator: " · ")
    }

    /// The contrast reading (WCAG ratio or APCA Lc) against the paired colour — only during a
    /// pair pick, when there's a comparison colour.
    private var contrastLabel: String? {
        guard let comparison = viewModel.comparison else { return nil }
        let sample = viewModel.sampleColor
        switch contrastStandard {
        case .apca, .both:
            return "Lc \(sample.toAPCAcontrastValue(with: comparison))"
        case .wcag:
            return String(format: "%.2f:1", sample.contrastRatio(with: comparison))
        }
    }

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

    private var slotLabel: String {
        switch viewModel.target {
        case .foreground: return PikaText.textColorForeground
        case .background: return PikaText.textColorBackground
        }
    }
}

/// The readout card tucked beside the loupe circle for the `.card` theme: the target slot,
/// the live format reading, and — during a pair pick — the live contrast against the paired
/// colour (mirroring the main window's active metric).
struct LoupeReadoutCard: View {
    @ObservedObject var viewModel: LoupeViewModel
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @Default(.contrastStandard) private var contrastStandard

    private let cardWidth: CGFloat = 176

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            slotIndicator
            formatReading
            if viewModel.comparison != nil { contrastReading }
        }
        .padding(12)
        .frame(width: cardWidth, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    private var slotIndicator: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(nsColor: viewModel.sampleColor))
                .frame(width: 14, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                )
            Text(slotLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }

    private var slotLabel: String {
        switch viewModel.target {
        case .foreground: return PikaText.textColorForeground
        case .background: return PikaText.textColorBackground
        }
    }

    private var formatReading: some View {
        Text(viewModel.sampleColor.toFormat(format: colorFormat, style: copyFormat))
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .textSelection(.disabled)
    }

    @ViewBuilder
    private var contrastReading: some View {
        if let comparison = viewModel.comparison {
            let metric = contrastMetric(sample: viewModel.sampleColor, comparison: comparison)
            HStack(spacing: 6) {
                Text(metric.label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer(minLength: 4)
                Text(metric.passes ? "✓" : "✗")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(metric.passes ? .green : .red)
            }
        }
    }

    private func contrastMetric(sample: NSColor, comparison: NSColor) -> (label: String, passes: Bool) {
        switch contrastStandard {
        case .apca, .both:
            let value = sample.toAPCACompliance(with: comparison).value
            let display = sample.toAPCAcontrastValue(with: comparison)
            return ("Lc \(display)", abs(value) >= 60)
        case .wcag:
            let ratio = sample.contrastRatio(with: comparison)
            return (String(format: "%.2f:1", ratio), ratio >= 4.5)
        }
    }
}
