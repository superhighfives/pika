import Defaults
import SwiftUI

private struct ValueWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// The colour value, shrunk to fit two lines as its column narrows. The font size is
/// computed deterministically from the (font-independent) column width, so — unlike
/// `minimumScaleFactor` + `lineLimit` — the wrap can't oscillate between one and two
/// lines during a resize.
struct AdaptiveValueText: View {
    let value: String
    let color: Color
    private let baseSize: CGFloat = 18
    private let minSize: CGFloat = 11
    @State private var width: CGFloat = 0

    private var fontSize: CGFloat {
        guard width > 4 else { return baseSize }
        let full = (value as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: baseSize)]).width
        guard full > 0 else { return baseSize }
        // Scale the font *proportionally* with the column width so the wrap point stays
        // put as the window resizes — no bistable jumping. The 1.5 factor (vs a
        // theoretical 2 for two full lines) leaves slack for word-boundary wrapping, so
        // long values still fit two lines instead of spilling to a truncated third.
        let scale = min(1, (1.5 * width) / full)
        return max(minSize, baseSize * scale)
    }

    var body: some View {
        Text(value)
            .foregroundColor(color)
            .font(.system(size: fontSize, weight: .regular))
            .lineLimit(2)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ValueWidthKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(ValueWidthKey.self) { width = $0 }
    }
}

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    @Default(.hideColorNames) var hideColorNames
    @Default(.showColorPreview) var showColorPreview
    @Environment(\.pikaAdaptiveVisibility) var adaptive

    @State var hoverVisible: Bool = false
    @State private var colorSpace = Defaults[.colorSpace]
    @State private var hoverTask: Task<Void, Never>?
    @State private var childHovered: Bool = false

    var body: some View {
        ZStack {
            Button(action: {
                NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil)
            }, label: {
                ZStack {
                    VStack(alignment: .leading, spacing: 2.0) {
                        // Visibility is size-aware (`adaptive.showsTypeLabels` already
                        // folds in the preview-pill overlap) so labels fade out as the
                        // window shrinks and return when it grows again.
                        let showsTypeLabel = adaptive.showsTypeLabels
                        Text(eyedropper.type.description)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(eyedropper.color.getUIColor().opacity(0.75))
                            .opacity(showsTypeLabel ? 1 : 0)
                            .animation(
                                showsTypeLabel
                                    ? .easeInOut(duration: 0.25).delay(0.3)
                                    : .easeInOut(duration: 0.2),
                                value: showsTypeLabel
                            )

                        VStack(alignment: .leading, spacing: 6.0) {
                            // Trailing gutter keeps the value clear of the copy /
                            // system-picker hover buttons; the value itself shrinks to fit
                            // two lines (see AdaptiveValueText).
                            AdaptiveValueText(
                                value: (eyedropper.color.usingColorSpace(colorSpace) ?? eyedropper.color)
                                    .toFormat(format: colorFormat, style: copyFormat),
                                color: Color(eyedropper.color.getUIColor())
                            )
                            .padding(.trailing, 32.0)

                            if !hideColorNames, adaptive.showsColorNames {
                                Text(eyedropper.getClosestColor())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(eyedropper.color.getUIColor())
                            }
                        }
                    }
                    .padding(.all, 10.0)
                    .modify {
                        let shadowColor: Color = eyedropper.color.getUIColor() == .white ? .black : .white
                        $0
                            .shadow(color: shadowColor.opacity(0.30), radius: 0, x: 0, y: 1)
                            .shadow(color: shadowColor.opacity(0.10), radius: 3, x: 0, y: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            })
            .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
            .focusable(false)

            VStack(spacing: 4.0) {
                Button(action: {
                    NSApp.sendAction(eyedropper.type.copySelector, to: nil, from: nil)
                }, label: {
                    IconImage(name: "doc.on.doc", resizable: true)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                })
                .buttonStyle(SwapButtonStyle(
                    isVisible: hoverVisible,
                    alt: PikaText.textColorCopy,
                    onHoverChange: { hover in
                        childHovered = hover
                        if hover { hoverTask?.cancel(); hoverTask = nil }
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)

                Button(action: {
                    NSApp.sendAction(eyedropper.type.systemPickerSelector, to: nil, from: nil)
                }, label: {
                    IconImage(name: "paintpalette", resizable: true)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                })
                .buttonStyle(SwapButtonStyle(
                    isVisible: hoverVisible,
                    alt: PikaText.textColorSystemPicker,
                    onHoverChange: { hover in
                        childHovered = hover
                        if hover { hoverTask?.cancel(); hoverTask = nil }
                    }
                ))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .focusable(false)
            }
            .padding(.all, 8.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            colorSpace = Defaults[.colorSpace]
        }
        .onHover { hover in
            if hover {
                hoverTask?.cancel()
                hoverTask = nil
                hoverVisible = true
            } else if hoverTask == nil, !childHovered {
                hoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    hoverVisible = false
                    hoverTask = nil
                }
            }
        }
    }
}

struct EyedropperButton_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperButton(
            eyedropper: Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!)
        )
        .frame(width: 170.0)
    }
}
