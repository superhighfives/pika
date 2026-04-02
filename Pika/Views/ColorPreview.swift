import Defaults
import SwiftUI

struct ColorPreview: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        ZStack {
            Color(background.color)
            Text("Aa")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(foreground.color))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12.0)
        }
        .frame(maxWidth: .infinity, minHeight: 44.0, maxHeight: 44.0)
    }
}

struct ColorPreview_Previews: PreviewProvider {
    static var previews: some View {
        let foreground = Eyedropper(type: .foreground, color: NSColor.white)
        let background = Eyedropper(type: .background, color: NSColor.black)
        ColorPreview(foreground: foreground, background: background)
            .frame(width: 420.0)
    }
}
