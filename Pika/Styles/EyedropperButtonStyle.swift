import SwiftUI

struct EyedropperButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(color)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .modify {
                if #available(OSX 11.0, *) {
                    $0.animation(.easeIn(duration: 0.15), value: color)
                } else {
                    $0
                }
            }
    }
}
