import SwiftUI

struct KeyboardShortcutItem: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State var title: String
    @State var event: String
    @State var keys: [String]
    @State private var highlight: Bool = false

    var body: some View {
        VStack(spacing: 6.0) {
            Text(title)
                .font(.system(size: 11, design: .rounded))
                .opacity(0.6)
            HStack(spacing: 4.0) {
                ForEach(keys, id: \.self) { key in
                    KeyboardShortcutKey { Text(key) }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(event))) { _ in
            self.highlight = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    self.highlight = false
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(highlight
            ? (colorScheme == .light ? Color.white.opacity(0.25) : Color.black.opacity(0.5))
            : (colorScheme == .light ? Color.white.opacity(0) : Color.black.opacity(0)))
    }
}

struct KeyboardShortcutItem_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutItem(title: "Copy Example", event: PikaConstants.ncTriggerPickForeground, keys: ["A", "B"])
    }
}
