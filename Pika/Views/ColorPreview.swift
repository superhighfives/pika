import Defaults
import SwiftUI

struct ColorPreview: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let isVisible: Bool
    let onSwap: () -> Void

    @State private var angle: Double = 0

    var body: some View {
        Button(action: {
            onSwap()
            angle -= 180
        }) {
            HStack(spacing: 8.0) {
                IconImage(name: "arrow.triangle.swap")
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut, value: angle)
                Text("Aa")
                    .font(.system(size: 15, weight: .bold))
                Text(NSLocalizedString("color.preview.sample", comment: "Sample preview text"))
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .foregroundColor(Color(foreground.color))
            .padding(.horizontal, 14.0)
            .padding(.vertical, 8.0)
        }
        .buttonStyle(.plain)
        .background(
            Capsule()
                .fill(Color(background.color))
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.3),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16.0)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isVisible)
        .onReceive(NotificationCenter.default.publisher(for: .triggerSwap)) { _ in
            angle -= 180
        }
        .transition(.opacity)
    }
}

struct ColorPreview_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            let foreground = Eyedropper(type: .foreground, color: NSColor.white)
            let background = Eyedropper(type: .background, color: NSColor.black)
            ColorPreview(foreground: foreground, background: background, isVisible: true, onSwap: {})
        }
        .frame(width: 420.0, height: 200.0)
    }
}
