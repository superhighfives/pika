import SwiftUI

struct EyedropperButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(color)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeIn(duration: 0.15), value: color)
    }
}
