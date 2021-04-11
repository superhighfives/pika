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
                    let contents
                        = "\(eyedropper.color.toFormat(format: colorFormat, hideFormat: Defaults[.hideFormatOnCopy]))"
                    pasteboard.setString(contents, forType: .string)
                }
                .toast(
                    isShowing: $showToast,
                    color: eyedropper.color.getUIColor(),
                    text: Text(String(NSLocalizedString("color.copy.toast", comment: "Copied")))
                )
        }
    }
}

struct EyedropperItem_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperItem(eyedropper: Eyedropper(type: .foreground, color: NSColor.black))
    }
}
