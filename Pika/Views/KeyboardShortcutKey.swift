import SwiftUI

struct KeyboardShortcutKey<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.vertical, 3.0)
            .padding(.horizontal, 7.0)
            .border(colorScheme == .light ? Color.gray.opacity(0.5) : Color.gray.opacity(0.5), width: 1)
            .cornerRadius(2)
    }
}

struct KeyboardShortcutKey_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutKey {
            Text("L")
        }
    }
}
