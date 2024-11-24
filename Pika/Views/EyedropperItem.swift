import Defaults
import SwiftUI

public extension NSPopUpButtonCell {
    override var focusRingType: NSFocusRingType {
        get { .none }
        // swiftlint:disable unused_setter_value
        set {}
        // swiftlint:enable unused_setter_value
    }
}

struct EyedropperItem: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var eyedropper: Eyedropper
    @State private var showToast: Bool = false
    @Default(.colorFormat) var colorFormat
    let pasteboard = NSPasteboard.general

    var body: some View {
        ZStack {
            EyedropperButton(eyedropper: eyedropper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerPick\(eyedropper.type.rawValue.capitalized)"))) { _ in
                    eyedropper.start()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerCopy\(eyedropper.type.rawValue.capitalized)"))) { _ in
                    showToast = true
                    pasteboard.clearContents()
                    let customFormat = Defaults[.customCopyFormat]
                    let contents
                        = "\(eyedropper.color.toFormat(format: colorFormat, style: Defaults[.copyFormat], customFormat: customFormat))"
                    pasteboard.setString(contents, forType: .string)
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerFormatHex"))) { _ in
                    colorFormat = ColorFormat.hex
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerFormatRGB"))) { _ in
                    colorFormat = ColorFormat.rgb
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerFormatHSB"))) { _ in
                    colorFormat = ColorFormat.hsb
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerFormatHSL"))) { _ in
                    colorFormat = ColorFormat.hsl
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerFormatCustom"))) { _ in
                    colorFormat = ColorFormat.hsl
                }
                .toast(
                    isShowing: $showToast,
                    color: eyedropper.color.getUIColor(),
                    text: Text(String(PikaText.textColorCopied))
                )
        }
    }
}

struct EyedropperItem_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperItem(eyedropper: Eyedropper(type: .foreground, color: NSColor.black))
    }
}
