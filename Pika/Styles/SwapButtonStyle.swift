import Combine
import SwiftUI

struct SwapButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false
    let isVisible: Bool

    private struct SwapButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        @State private var isHovered: Bool = false
        let configuration: Configuration
        let isVisible: Bool

        func getBackgroundColor(colorScheme: ColorScheme) -> Color {
            if #available(OSX 11.0, *) {
                return colorScheme == .dark
                    ? Color(red: 27 / 255, green: 27 / 255, blue: 27 / 255)
                    : Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
            } else {
                return colorScheme == .dark
                    ? Color(red: 50 / 255, green: 52 / 255, blue: 59 / 255)
                    : Color(red: 236 / 255, green: 236 / 255, blue: 236 / 255)
            }
        }

        var body: some View {
            let fgColor = colorScheme == .dark ? Color.white : .black
            let bgColor: Color = getBackgroundColor(colorScheme: colorScheme)

            HStack {
                configuration.label
                if isHovered {
                    Text(NSLocalizedString("color.pick.swap", comment: "Swap"))
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
            .opacity(isVisible ? (configuration.isPressed ? 0.8 : 1.0) : 0.0)
            .foregroundColor(fgColor.opacity(0.8))
            .animation(.easeInOut)
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        SwapButtonStyleView(configuration: configuration, isVisible: isVisible)
    }
}
