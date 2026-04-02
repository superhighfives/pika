import Defaults
import SwiftUI

struct ColorPreview: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        ZStack {
            Color(background.color)
            HStack(spacing: 12.0) {
                Text("Aa")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(foreground.color))
                Text("The quick brown fox jumps over the lazy dog")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(foreground.color))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 12.0)
            .frame(maxWidth: .infinity, alignment: .leading)
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
