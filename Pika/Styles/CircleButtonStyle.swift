import Combine
import SwiftUI

struct CircleButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false
    let isVisible: Bool

    private struct CircleButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        let configuration: Configuration
        let isVisible: Bool

        func getBackgroundColor(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 27 / 255, green: 27 / 255, blue: 27 / 255)
                : Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
        }

        var body: some View {
            let fgColor = colorScheme == .dark ? Color.white : .black
            let bgColor: Color = getBackgroundColor(colorScheme: colorScheme)

            configuration.label
                .padding(.all, 8)
                .background(
                    ZStack {
                        Circle()
                            .fill(bgColor)
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: configuration.isPressed ? 1 : 2,
                                x: 0,
                                y: configuration.isPressed ? 1 : 2
                            )
                            .overlay(
                                Circle()
                                    .stroke(fgColor.opacity(0.1))
                            )
                    }
                )
                .opacity(isVisible ? (configuration.isPressed ? 0.8 : 1.0) : 0.0)
                .foregroundColor(fgColor.opacity(0.8))
                .animation(.easeInOut, value: isVisible)
                .animation(.easeInOut, value: configuration.isPressed)
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        CircleButtonStyleView(configuration: configuration, isVisible: isVisible)
    }
}
