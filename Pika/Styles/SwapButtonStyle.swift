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
            let bgColor = colorScheme == .dark ? Color.black : .white

            configuration.label
                .padding(8)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .shadow(
                                color: Color.white.opacity(0.5),
                                radius: configuration.isPressed ? 3 : 8,
                                x: configuration.isPressed ? -4 : -12,
                                y: configuration.isPressed ? -4 : -12
                            )
                            .shadow(
                                color: Color.black.opacity(0.5),
                                radius: configuration.isPressed ? 3 : 8,
                                x: configuration.isPressed ? 4 : 12,
                                y: configuration.isPressed ? 4 : 12
                            )
                            .blendMode(.overlay)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(bgColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.white.opacity(0.2))
                            )
                    }
                )
                .onHover { hover in
                    self.isHovered = hover
                }
                .scaleEffect(self.isHovered ? 1.1 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .opacity(isVisible ? 1.0 : 0.0)
                .foregroundColor(fgColor)
                .animation(.spring())
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        SwapButtonStyleView(configuration: configuration, isVisible: isVisible)
    }
}
