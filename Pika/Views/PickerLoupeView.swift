import Defaults
import SwiftUI

/// The loupe card contents: a magnified pixel grid with a crosshair on top, then the
/// v1 overlays stacked in the card body — slot indicator, live format reading, and live
/// contrast against the paired colour (mirroring the main window's active metric).
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
struct PickerLoupeView: View {
    @ObservedObject var viewModel: LoupeViewModel
    @Default(.colorFormat) private var colorFormat
    @Default(.copyFormat) private var copyFormat
    @Default(.contrastStandard) private var contrastStandard

    private let gridSize: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            magnifiedGrid
            body(width: gridSize)
        }
        .frame(width: gridSize)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Magnified grid + crosshair

    private var magnifiedGrid: some View {
        ZStack {
            Color(nsColor: viewModel.sampleColor)
            if let image = viewModel.image {
                Image(decorative: image, scale: 1.0)
                    .interpolation(.none)
                    .resizable()
            }
            crosshair
        }
        .frame(width: gridSize, height: gridSize)
        .clipped()
    }

    private var crosshair: some View {
        // One magnified pixel cell, outlined, marking the sampled centre pixel.
        let cell = gridSize / CGFloat(max(1, viewModel.pixelCount))
        return Rectangle()
            .strokeBorder(Color.white, lineWidth: 1)
            .frame(width: cell, height: cell)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.black, lineWidth: 1)
                    .padding(-1)
            )
    }

    // MARK: - Card body

    private func body(width _: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            slotIndicator
            formatReading
            if viewModel.comparison != nil { contrastReading }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
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
