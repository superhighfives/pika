import Defaults
import SwiftUI

/// The circular magnifier that sits directly on the cursor, in the style of the system
/// colour sampler: a round window of magnified pixels with the sampled centre pixel
/// outlined. Paired with `LoupeReadoutCard`, which carries the live readouts beside it.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
struct LoupeCircle: View {
    @ObservedObject var viewModel: LoupeViewModel

    /// Diameter of the magnified disc (excludes the shadow padding around it).
    var diameter: CGFloat = 140
    /// Breathing room so the drop shadow isn't clipped by the hosting panel.
    static let shadowPadding: CGFloat = 10

    var body: some View {
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
        .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 3))
        .overlay(Circle().strokeBorder(Color.black.opacity(0.22), lineWidth: 1).padding(1.5))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        .padding(Self.shadowPadding)
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
}

/// The readout card tucked beside the loupe circle: the target slot, the live format
/// reading, and — during a pair pick — the live contrast against the paired colour
/// (mirroring the main window's active metric).
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
        case .foreground: return PikaText.textPickerLoupeForeground
        case .background: return PikaText.textPickerLoupeBackground
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
