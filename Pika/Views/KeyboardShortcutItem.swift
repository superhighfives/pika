import SwiftUI

struct KeyboardShortcutItem: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let title: String
    let notificationName: Notification.Name
    let keys: [String]
    @State private var highlight: Bool = false

    var body: some View {
        VStack(spacing: 2.0) {
            Text(title)
                .font(.system(size: 11, design: .rounded))
                .opacity(0.6)
                .padding([.bottom, .leading, .trailing], 6.0)
                .padding(.top, 0.0)
                .multilineTextAlignment(.center)
            HStack(spacing: 4.0) {
                ForEach(keys, id: \.self) { key in
                    KeyboardShortcutKey { Text(key) }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in
            highlight = true
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation {
                    highlight = false
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
        KeyboardShortcutItem(title: "Copy example but with a much longer text",
                             notificationName: .triggerPickForeground, keys: ["A", "B"])
            .frame(width: 100.0, height: 100.0)
    }
}
