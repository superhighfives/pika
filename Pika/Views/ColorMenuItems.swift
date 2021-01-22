import Defaults
import SwiftUI

struct ColorMenuItems: View {
    var eyedropper: Eyedropper
    @Default(.colorFormat) var colorFormat
    let pasteboard = NSPasteboard.general

    var body: some View {
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toFormat(format: colorFormat), forType: .string)
        }, label: { Text("Copy current format") })
        VStack {
            Divider()
        }
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toHexString(), forType: .string)
        }, label: { Text("Copy HEX values") })
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toRGB8BitString(), forType: .string)
        }, label: { Text("Copy RGB values") })
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toHSB8BitString(), forType: .string)
        }, label: { Text("Copy HSB values") })
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toHSL8BitString(), forType: .string)
        }, label: { Text("Copy HSL values") })
    }
}

struct ColorMenuItems_Previews: PreviewProvider {
    static var previews: some View {
        let eyedropper = Eyedropper(title: "Foreground", color: NSColor.white)
        ColorMenuItems(eyedropper: eyedropper)
    }
}
