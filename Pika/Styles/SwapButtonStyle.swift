import Combine
import SwiftUI

struct SwapButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false
    let isVisible: Bool

    private struct SwapButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        let configuration: Configuration
        let isVisible: Bool
        @State private var isHovered: Bool = false

        var body: some View {
            let fgColor = colorScheme == .dark ? Color.white : .black
            let bgColor = colorScheme == .dark
                ? Color(red: 0.1, green: 0.1, blue: 0.1)
                : Color(red: 0.95, green: 0.95, blue: 0.95)

            HStack {
                configuration.label
                if isHovered {
                    Text("Swap")
                        .font(.system(size: 12.0))
                }
            }
            .padding(.horizontal, isHovered ? 12 : 8)
            .padding(.vertical, 8)
            .mask(RoundedRectangle(cornerRadius: 100.0, style: .continuous))
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 100.0, style: .continuous)
                        .fill(bgColor)
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: configuration.isPressed ? 1 : 2,
                            x: 0,
                            y: configuration.isPressed ? 1 : 2
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 100.0, style: .continuous)
                                .stroke(fgColor.opacity(0.1))
                        )
                }
            )
            .onHover { hover in
                self.isHovered = hover
            }
            .scaleEffect(self.isHovered ? 1.1 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(isVisible ? 1.0 : 0.0)
            .foregroundColor(fgColor.opacity(0.8))
            .animation(.spring())
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        SwapButtonStyleView(configuration: configuration, isVisible: isVisible)
    }
}
