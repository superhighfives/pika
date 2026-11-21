import SwiftUI

/// Shared surface for the footer and palette drawer. In light mode the under-window
/// vibrancy material washes out to near-nothing, so use the standard window background
/// for a clearly-defined panel; dark mode keeps the material, which reads well there.
struct AdaptivePanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            VisualEffect(
                material: NSVisualEffectView.Material.underWindowBackground,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            )
        } else {
            Color(NSColor.windowBackgroundColor)
        }
    }
}

/// Divider that reads as a recessed seam in both appearances. The system `Divider`
/// renders too light over the footer/drawer materials in light mode (looks white rather
/// than a darker separator), so tint explicitly with `primary`, which flips per scheme.
struct AdaptiveDivider: View {
    static let thickness: CGFloat = 1

    @Environment(\.colorScheme) private var colorScheme
    var axis: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.24))
            .frame(
                width: axis == .vertical ? Self.thickness : nil,
                height: axis == .horizontal ? Self.thickness : nil
            )
    }
}

/// Small floating capsule shown when the adaptive layout is hiding enabled elements.
/// Tapping it grows the window just enough to reveal them again.
struct ExpandToFitButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5.0) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .semibold))
                Text(PikaText.textExpandToFit)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10.0)
            .padding(.vertical, 5.0)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12)))
            .opacity(hovering ? 1.0 : 0.9)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovering = $0 }
        .help(PikaText.textExpandToFit)
    }
}
