import Defaults
import SwiftUI

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
                            Text((eyedropper.color.usingColorSpace(colorSpace) ?? eyedropper.color).toFormat(format: colorFormat, style: copyFormat))
                                .foregroundColor(eyedropper.color.getUIColor())
                                .font(.system(size: 18, weight: .regular))
                                // Shrink long formats (OKLCH/RGB) to stay within two
                                // lines as the window narrows, rather than wrapping to
                                // three lines or clipping. The trailing padding keeps the
                                // text clear of the copy / system-picker hover buttons.
                                .lineLimit(2)
                                .minimumScaleFactor(0.5)
                                // Bound the text to the column width (minus the button
                                // gutter) so it wraps/scales inside its column instead of
                                // reporting its single-line ideal width and overflowing
                                // past the window edge.
                                .padding(.trailing, 32.0)
                                .frame(maxWidth: .infinity, alignment: .leading)

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
