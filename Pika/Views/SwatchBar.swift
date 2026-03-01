import Defaults
import SwiftUI

struct Swatch: Identifiable, Equatable {
    let id: String
    /// Full-precision color used for rendering and format conversion.
    let color: NSColor
    /// Hex identifier used for color history lookups and tap-to-copy.
    let hex: String
    let name: String?

    static func == (lhs: Swatch, rhs: Swatch) -> Bool {
        lhs.id == rhs.id
    }
}

/// Shared component for color history and palette bars: equal-width colored rectangles
/// with hover text and a tap callback. Uses GeometryReader to divide available width evenly.
/// Hover text dynamically reflects the currently selected color format.
struct SwatchBar: View {
    let title: String
    let swatches: [Swatch]
    let onTap: (Swatch) -> Void

    @Default(.colorFormat) var colorFormat
    @State private var hoveredSwatch: Swatch?
    @State private var isHoveringBar = false

    private func hoverText(for swatch: Swatch) -> String {
        // Hex keeps '#'; other formats show just the values (no function wrapper).
        let style: CopyFormat = colorFormat == .hex ? .css : .unformatted
        let formatted = swatch.color.toFormat(format: colorFormat, style: style)
        if let name = swatch.name {
            return "\(name) (\(formatted))"
        }
        return formatted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text(hoveredSwatch.map { hoverText(for: $0) } ?? " ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHoveringBar ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringBar)
            }
            .padding(.horizontal, 12.0)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(swatches) { swatch in
                        Rectangle()
                            .fill(Color(swatch.color))
                            .frame(width: geometry.size.width / CGFloat(swatches.count))
                            .onHover { hovering in
                                if hovering { hoveredSwatch = swatch }
                            }
                            .onTapGesture {
                                onTap(swatch)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4.0))
                // Keep hoveredSwatch set on exit so the text doesn't change width
                // during the opacity fade-out (which would cause a visible slide).
                .onHover { hovering in
                    isHoveringBar = hovering
                }
            }
            .frame(height: 16)
            .padding(.horizontal, 12.0)
        }
    }
}

/// Shared styling for swatch sections (color history and palette bars).
struct SwatchSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.top, 10.0)
            .padding(.bottom, 12.0)
            .background(VisualEffect(
                material: NSVisualEffectView.Material.underWindowBackground,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            ))
    }
}

extension View {
    func swatchSectionStyle() -> some View {
        modifier(SwatchSectionStyle())
    }
}
