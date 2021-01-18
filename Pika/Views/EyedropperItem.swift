import Defaults
import SwiftUI

struct EyedropperItem: View {
    @ObservedObject var eyedropper: Eyedropper
    @State private var showToast: Bool = false
    @Default(.colorFormat) var colorFormat
    let pasteboard = NSPasteboard.general

    var body: some View {
        ZStack {
            EyedropperButton(eyedropper: eyedropper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("trigger\(eyedropper.title)"))) { _ in
                    eyedropper.start()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: Notification.Name("triggerCopy\(eyedropper.title)"))) { _ in
                    showToast = true
                    pasteboard.clearContents()
                    let contents = "\(eyedropper.color.toFormat(format: colorFormat))"
                    pasteboard.setString(contents, forType: .string)
                }
                .toast(isShowing: $showToast, text:
                    Text("Copied \(eyedropper.title)"))

            ColorMenu(eyedropper: eyedropper)
                .shadow(radius: 0, x: 0, y: 1)
                .opacity(0.8)
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8.0)
        }
    }
}

struct EyedropperItem_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperItem(eyedropper: Eyedropper(title: "Foreground", color: NSColor.black))
    }
}
