import SwiftUI

struct ColorMenuItems: View {
    var eyedropper: Eyedropper
    let pasteboard = NSPasteboard.general

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Text(eyedropper.title)
            Divider()
        }
        Button(action: {
            pasteboard.clearContents()
            pasteboard.setString(eyedropper.color.toHexString(), forType: .string)
        }, label: { Text("Copy color hex") })
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
