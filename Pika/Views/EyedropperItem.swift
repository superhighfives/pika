import SwiftUI

struct EyedropperItem: View {
    @ObservedObject var eyedropper: Eyedropper

    var body: some View {
        let uiColor: Color = eyedropper.color.luminance < 0.5 ? Color.white : Color.black

        ZStack {
            EyedropperButton(eyedropper: eyedropper, uiColor: uiColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Trigger\(eyedropper.title)"))) { _ in
                    eyedropper.start()
                }

            Text(eyedropper.color.luminance.description)

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
