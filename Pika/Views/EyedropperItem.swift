import Defaults
import SwiftUI

public extension NSPopUpButtonCell {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
}

struct EyedropperItem: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var eyedropper: Eyedropper
    @State private var showToast: Bool = false
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    let pasteboard = NSPasteboard.general
    var body: some View {
        ZStack {
            EyedropperButton(eyedropper: eyedropper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerPick\(eyedropper.type.rawValue.capitalized)")))
            { _ in
                eyedropper.start()
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerCopy\(eyedropper.type.rawValue.capitalized)")))
            { _ in
                showToast = true
                pasteboard.clearContents()
                let contents
                    = "\(eyedropper.color.toFormat(format: colorFormat, style: Defaults[.copyFormat]))"
                pasteboard.setString(contents, forType: .string)
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerSystemPicker\(eyedropper.type.rawValue.capitalized)")))
            { _ in
                let panel = NSColorPanel.shared
                if panel.isVisible, panel.title == "\(eyedropper.type.rawValue.capitalized)" {
                    panel.close()
                } else {
                    eyedropper.picker()
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerFormatHex")))
            { _ in
                if copyFormat != .swiftUI {
                    colorFormat = ColorFormat.hex
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerFormatRGB")))
            { _ in
                colorFormat = ColorFormat.rgb
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerFormatHSB")))
            { _ in
                colorFormat = ColorFormat.hsb
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerFormatHSL")))
            { _ in
                if copyFormat != .swiftUI {
                    colorFormat = ColorFormat.hsl
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("triggerFormatOpenGL")))
            { _ in
                if copyFormat != .swiftUI {
                    colorFormat = ColorFormat.opengl
                }
            }
            .onChange(of: copyFormat) {
                if copyFormat == .swiftUI {
                    if PikaConstants.disabledFormats.contains(colorFormat) {
                        colorFormat = .rgb
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name(PikaConstants.ncTriggerFormatLAB)))
            { _ in
                colorFormat = .lab
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
            .frame(width: 180.0)
    }
}
