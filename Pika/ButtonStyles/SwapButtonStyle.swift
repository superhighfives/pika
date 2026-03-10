import SwiftUI

struct SwapButtonStyle: ButtonStyle {
    let isVisible: Bool
    let alt: String
    var ltr = false

    private struct SwapButtonStyleView: View {
        @Environment(\.colorScheme) var colorScheme: ColorScheme

        let configuration: Configuration
        let isVisible: Bool
        let alt: String
        let ltr: Bool

        var body: some View {
            let fgColor = colorScheme == .dark ? Color.white : .black
            let bgColor = Color.pikaControlBackground(for: colorScheme)

            HStack {
                if ltr {
                    configuration.label
                    if isVisible {
                        Text(alt)
                            .font(.system(size: 12.0))
                            .padding(.trailing, 2)
                    }
                } else {
                    if isVisible {
                        Text(alt)
                            .font(.system(size: 12.0))
                            .padding(.leading, 6)
                    }
                    configuration.label
                }
            }
            .padding(.horizontal, 8)
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
            .opacity(isVisible ? (configuration.isPressed ? 0.8 : 1.0) : 0.0)
            .foregroundColor(fgColor.opacity(0.8))
            .frame(height: 32.0)
            .animation(.easeInOut, value: isVisible)
            .animation(.easeInOut, value: configuration.isPressed)
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        SwapButtonStyleView(configuration: configuration, isVisible: isVisible, alt: alt, ltr: ltr)
    }
}
