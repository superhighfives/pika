import Defaults
import SwiftUI

/// Text laid out along a circular arc, engraved-lens style. `centerAngle` is measured
/// clockwise from the top (0 = 12 o'clock); set `flip` for the bottom half so glyphs stay
/// upright and read left-to-right.
struct CircularText: View {
    let text: String
    var radius: CGFloat
    var font: Font = .system(size: 12, weight: .semibold, design: .monospaced)
    var centerAngle: Double = 0
    var charSpacing: Double = 0.13 // radians between glyph centres
    var flip: Bool = false

    var body: some View {
        let chars = Array(text)
        let count = chars.count
        ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, character in
                let step = (Double(index) - Double(count - 1) / 2.0) * charSpacing
                let theta = centerAngle + (flip ? -step : step)
                Text(String(character))
                    .font(font)
                    .rotationEffect(.radians(flip ? theta + .pi : theta))
                    .offset(x: radius * sin(theta), y: -radius * cos(theta))
            }
        }
    }
}

/// The loupe, styled like a camera lens: a circular window of magnified pixels (the sampled
/// centre pixel outlined) set into a dark rim engraved with the live readouts — the colour
/// format around the top, the target slot and contrast around the bottom.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
struct LoupeCircle: View {
    @ObservedObject var viewModel: LoupeViewModel
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @Default(.contrastStandard) private var contrastStandard

    /// Diameter of the magnified glass (excludes the rim and engraved text around it).
    var diameter: CGFloat = 150
    /// Room around the glass for the rim, engraved text and drop shadow.
    static let inset: CGFloat = 50

    /// Total square side of the view (and its hosting panel).
    static func totalSize(diameter: CGFloat = 150) -> CGFloat { diameter + inset * 2 }

    private var textRadius: CGFloat { diameter / 2 + 18 }
    private let engraved: Font = .system(size: 12, weight: .semibold, design: .monospaced)

    var body: some View {
        ZStack {
            // Lens barrel: the dark rim the text is engraved on.
            Circle()
                .stroke(Color.black.opacity(0.82), lineWidth: 34)
                .frame(width: textRadius * 2, height: textRadius * 2)

            glass

            // Bright inner edge where the glass meets the rim.
            Circle()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 3)
                .frame(width: diameter, height: diameter)

            // Engraved readouts.
            CircularText(text: topText, radius: textRadius, font: engraved)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1)
            CircularText(text: bottomText, radius: textRadius, font: engraved, centerAngle: .pi, flip: true)
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 1)
        }
        .frame(width: Self.totalSize(diameter: diameter), height: Self.totalSize(diameter: diameter))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 3)
    }

    // MARK: - Glass

    private var glass: some View {
        ZStack {
            Color(nsColor: viewModel.sampleColor)
            if let image = viewModel.image {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
            }
            centerCell
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    /// One magnified pixel cell, outlined, marking the sampled centre pixel.
    private var centerCell: some View {
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

    // MARK: - Engraved text

    private var topText: String {
        viewModel.sampleColor.toFormat(format: colorFormat, style: copyFormat).uppercased()
    }

    private var bottomText: String {
        let slot = slotLabel.uppercased()
        guard let comparison = viewModel.comparison else { return slot }
        let metric = contrastMetric(sample: viewModel.sampleColor, comparison: comparison)
        return "\(slot) · \(metric.label) \(metric.passes ? "✓" : "✗")"
    }

    private var slotLabel: String {
        switch viewModel.target {
        case .foreground: return PikaText.textPickerLoupeForeground
        case .background: return PikaText.textPickerLoupeBackground
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
