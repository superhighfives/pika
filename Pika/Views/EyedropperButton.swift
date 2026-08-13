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
    @State private var valueInvalid: Bool = false

    var body: some View {
        ZStack {
            // Background pick target: a click anywhere that isn't the editable value (or the
            // non-interactive labels above it, which fall through) starts a pick.
            Button(action: {
                NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil)
            }, label: {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            })
            .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
            .focusable(false)

            // Content overlay, lifted out of the pick button so the value's fields receive
            // clicks. The type label and colour name disable hit-testing so clicks fall
            // through to the pick button behind them.
            VStack(alignment: .leading, spacing: 2.0) {
                // Visibility is size-aware (`adaptive.showsTypeLabels` already folds in the
                // preview-pill overlap) so labels fade out as the window shrinks and return
                // when it grows again. The invalid pill overrides the fade so it's never hidden.
                let showsTypeLabel = adaptive.showsTypeLabels
                HStack(alignment: .firstTextBaseline, spacing: 6.0) {
                    Text(eyedropper.type.description)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(eyedropper.color.getUIColor().opacity(0.75))
                    if valueInvalid {
                        InvalidInputPill(uiColor: eyedropper.color.getUIColor())
                    }
                    // Reserves the pill's height in this row at all times (zero width, so it
                    // never otherwise affects layout) so toggling the pill doesn't change the
                    // row's height. The content below is anchored `.bottomLeading` in its parent
                    // frame, so any height change here shifts this label — the "Foreground" /
                    // "Background" text visibly jumping by a pixel each time invalid state was
                    // entered or exited.
                    InvalidInputPill(uiColor: .clear)
                        .fixedSize()
                        .frame(width: 0)
                        .accessibilityHidden(true)
                }
                .opacity(showsTypeLabel || valueInvalid ? 1 : 0)
                .animation(
                    showsTypeLabel
                        ? .easeInOut(duration: 0.25).delay(0.3)
                        : .easeInOut(duration: 0.2),
                    value: showsTypeLabel
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 6.0) {
                    // Trailing gutter keeps the value clear of the copy / system-picker hover
                    // buttons; the value shrinks to fit as its column narrows.
                    EditableColorValue(
                        eyedropper: eyedropper,
                        format: colorFormat,
                        style: copyFormat,
                        colorSpace: colorSpace,
                        isInvalid: $valueInvalid
                    )
                    .padding(.trailing, 32.0)

                    if !hideColorNames, adaptive.showsColorNames {
                        Text(eyedropper.getClosestColor())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(eyedropper.color.getUIColor())
                            .allowsHitTesting(false)
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
