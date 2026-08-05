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
    @Default(.loupeTheme) private var theme

    /// Fixed square side of the view (and its hosting panel), sized for the larger theme.
    static let totalSize: CGFloat = 240

    private let lensGlass: CGFloat = 150
    private let badgeGlass: CGFloat = 200
    private let lensFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    private let badgeFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)

    var body: some View {
        ZStack {
            switch theme {
            case .lens: lens
            case .badge: badge
            }
        }
        .frame(width: Self.totalSize, height: Self.totalSize)
        .shadow(color: .black.opacity(0.3), radius: 5, y: 2)
    }

    // MARK: - Lens theme

    private var lens: some View {
        let textRadius = lensGlass / 2 + 16
        return ZStack {
            // Rim filled with the hovered colour, engraved with the readouts.
            Circle()
                .stroke(Color(nsColor: viewModel.sampleColor), lineWidth: 28)
                .frame(width: textRadius * 2, height: textRadius * 2)
            glass(diameter: lensGlass)
            Circle()
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: lensGlass, height: lensGlass)
            CircularText(text: formatText, radius: textRadius, nsFont: lensFont)
                .foregroundStyle(lensTextColor)
            CircularText(text: lensBottomText, radius: textRadius, nsFont: lensFont,
                         centerAngle: .pi, flip: true)
                .foregroundStyle(lensTextColor)
        }
    }

    /// White on dark colours, black on light ones, so the engraving stays legible.
    private var lensTextColor: Color {
        let srgb = viewModel.sampleColor.usingColorSpace(.sRGB) ?? viewModel.sampleColor
        let luminance = 0.2126 * srgb.redComponent + 0.7152 * srgb.greenComponent + 0.0722 * srgb.blueComponent
        return luminance < 0.55 ? .white : .black
    }

    private var lensBottomText: String {
        viewModel.colorName.isEmpty ? slotLabel : "\(slotLabel) · \(viewModel.colorName)"
    }

    // MARK: - Badge theme

    private var badge: some View {
        let badgeRadius = badgeGlass / 2 - 18
        return ZStack {
            glass(diameter: badgeGlass)
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
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
        let arc = Double(width / radius) + 0.42 // text arc + rounded-cap padding
        let fraction = min(0.95, arc / (2 * .pi))
        // Circle().trim starts at 3 o'clock and runs clockwise, so the top (12 o'clock) is
        // 0.75; convert the clockwise-from-top centre angle to that space.
        let centre = (0.75 + centerAngle / (2 * .pi)).truncatingRemainder(dividingBy: 1)
        return ZStack {
            Circle()
                .trim(from: centre - fraction / 2, to: centre + fraction / 2)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
            CircularText(text: text, radius: radius, nsFont: badgeFont,
                         centerAngle: centerAngle, flip: flip)
                .foregroundStyle(Color.black.opacity(0.85))
        }
    }

    private var badgeTopText: String { formatText.uppercased() }

    private var badgeBottomText: String {
        let slot = slotLabel.uppercased()
        let name = viewModel.colorName.uppercased()
        return name.isEmpty ? slot : "\(slot) · \(name)"
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
        case .foreground: return PikaText.textPickerLoupeForeground
        case .background: return PikaText.textPickerLoupeBackground
        }
    }
}
