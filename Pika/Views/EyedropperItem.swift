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
    let pasteboard = NSPasteboard.general

    var body: some View {
        ZStack {
            EyedropperButton(eyedropper: eyedropper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerPick\(eyedropper.title)"))) { _ in
                    eyedropper.start()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerCopy\(eyedropper.title)"))) { _ in
                    showToast = true
                    pasteboard.clearContents()
                    let contents = "\(eyedropper.color.toFormat(format: colorFormat))"
                    pasteboard.setString(contents, forType: .string)
                }
                .toast(
                    isShowing: $showToast,
                    color: eyedropper.getUIColor(),
                    text: Text("Copied \(eyedropper.title.lowercased())")
                )

            ColorMenu(eyedropper: eyedropper)
                .shadow(
                    color: (colorScheme == .light ? Color.white : Color.black).opacity(0.25),
                    radius: 0,
                    x: 0,
                    y: 1
                )
                .opacity(0.8)
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8.0)
                .modify {
                    if colorScheme == .dark {
                        $0.colorMultiply(Color.white)
                    } else {
                        $0
                    }
                }
        }
    }
}

struct EyedropperItem_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperItem(eyedropper: Eyedropper(title: "Foreground", color: NSColor.black))
    }
}
