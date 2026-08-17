import SwiftUI

/// Lays out children left-to-right, wrapping whole fragments (never mid-word, since each
/// fragment is measured and placed atomically) onto a new line once a fragment no longer fits —
/// so a squeezed row grows to two lines instead of clipping.
struct FlowLayout: Layout {
    var lineSpacing: CGFloat = 2
    /// Backstop for a caller that's already sized its content to fit in this many lines (e.g. by
    /// shrinking its font to target `maxLines * width`): once reached, remaining fragments pack
    /// onto the last line instead of starting a new one, so a rounding/estimation miss overflows
    /// horizontally rather than growing a line the caller didn't budget height for. `nil` (the
    /// default) wraps to as many lines as needed.
    var maxLines: Int?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0, lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0, totalHeight: CGFloat = 0
        var line = 1
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0, lineWidth + size.width > maxWidth, maxLines.map({ line < $0 }) ?? true {
                totalHeight += lineHeight + lineSpacing
                totalWidth = max(totalWidth, lineWidth)
                lineWidth = 0
                lineHeight = 0
                line += 1
            }
            lineWidth += size.width
            lineHeight = max(lineHeight, size.height)
        }
        totalHeight += lineHeight
        totalWidth = max(totalWidth, lineWidth)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        var line = 1
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX, maxLines.map({ line < $0 }) ?? true {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
                line += 1
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}
