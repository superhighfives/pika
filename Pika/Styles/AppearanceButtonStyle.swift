import SwiftUI

struct AppearanceButtonStyle: ButtonStyle {
    var title: String
    var description: String
    var selected = false

    func makeBody(configuration: Self.Configuration) -> some View {
        VStack {
            configuration.label
                .background(LinearGradient(
                    gradient: .init(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.1),
                        Color(red: 0.0, green: 0.0, blue: 0.0)
                    ]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0, y: 1)
                ))
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                .overlay(
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .fill(LinearGradient(
                                gradient: .init(colors: [.black.opacity(0), .black]),
                                startPoint: .init(x: 0, y: 0),
                                endPoint: .init(x: 1, y: 1)
                            ))
                            .frame(maxWidth: 80, maxHeight: .infinity)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .modify {
                            if #available(OSX 11.0, *) {
                                $0.stroke(Color.accentColor.opacity(selected ? 1 : 0), lineWidth: 2)
                            } else {
                                $0.stroke(.blue.opacity(selected ? 1 : 0), lineWidth: 2)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: selected)
                )
            VStack(spacing: 4.0) {
                Text(title)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20.0)
            }
        }
        .contentShape(Rectangle())
    }
}
