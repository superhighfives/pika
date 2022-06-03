import SwiftUI

struct AppearanceButtonStyle: ButtonStyle {
    var text: String
    var selected = false

    func makeBody(configuration: Self.Configuration) -> some View {
        VStack {
            configuration.label
                .background(Color.black)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .stroke(.blue.opacity(selected ? 1 : 0), lineWidth: 2)
                )
                .modify {
                    if #available(OSX 11.0, *) {
                        $0.animation(.easeIn(duration: 0.15), value: Color.white)
                    } else {
                        $0
                    }
                }
            Text(text)
        }
    }
}
