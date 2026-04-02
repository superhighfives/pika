import Defaults
import SwiftUI

struct ColorPreview: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        HStack(spacing: 8.0) {
            Text("Aa")
                .font(.system(size: 15, weight: .bold))
            Text("The quick brown fox jumps over the lazy dog")
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundColor(Color(foreground.color))
        .padding(.horizontal, 14.0)
        .padding(.vertical, 8.0)
        .background(
            Capsule()
                .fill(Color(background.color))
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16.0)
        .transition(AnyTransition.scale(scale: 0.8).combined(with: .opacity))
    }
}

struct ColorPreview_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            let foreground = Eyedropper(type: .foreground, color: NSColor.white)
            let background = Eyedropper(type: .background, color: NSColor.black)
            ColorPreview(foreground: foreground, background: background)
        }
        .frame(width: 420.0, height: 200.0)
    }
}
