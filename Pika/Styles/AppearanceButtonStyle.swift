import SwiftUI

struct AppearanceButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var title: String
    var description: String
    var selected = false

    let darkBaseColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    let lightBaseColor = Color(red: 0.975, green: 0.975, blue: 0.975)

    func makeOverlay() -> some View {
        HStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [
                                    darkBaseColor.opacity(0.5),
                                    darkBaseColor.opacity(0),
                                ]
                                : [
                                    lightBaseColor.opacity(0.9),
                                    lightBaseColor.opacity(0),
                                ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: 25, maxHeight: .infinity)
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [
                                    darkBaseColor.opacity(0),
                                    darkBaseColor.opacity(0.5),
                                ]
                                : [
                                    lightBaseColor.opacity(0),
                                    lightBaseColor.opacity(0.9),
                                ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: 25, maxHeight: .infinity)
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        VStack {
            configuration.label
                .background(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [darkBaseColor, .black]
                                : [lightBaseColor, .white]),
                        startPoint: .init(x: 0, y: 0),
                        endPoint: .init(x: 0, y: 1)
                    )
                )
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(
                    .easeInOut(duration: 0.1), value: configuration.isPressed
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    makeOverlay()
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                )
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.1),
                    radius: 2, x: 0, y: 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .stroke(
                            Color.accentColor.opacity(selected ? 1 : 0),
                            lineWidth: 2
                        )
                        .animation(.easeInOut(duration: 0.3), value: selected)
                )
            VStack(spacing: 4.0) {
                Text(title).foregroundColor(.primary)
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

struct StyledContentView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let title: String
    let description: String
    let content: Content

    let darkBaseColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    let lightBaseColor = Color(red: 0.975, green: 0.975, blue: 0.975)

    init(
        title: String, description: String, @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }

    func makeOverlay() -> some View {
        HStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [
                                    darkBaseColor.opacity(0.5),
                                    darkBaseColor.opacity(0),
                                ]
                                : [
                                    lightBaseColor.opacity(0.9),
                                    lightBaseColor.opacity(0),
                                ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: 25, maxHeight: .infinity)
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [
                                    darkBaseColor.opacity(0),
                                    darkBaseColor.opacity(0.5),
                                ]
                                : [
                                    lightBaseColor.opacity(0),
                                    lightBaseColor.opacity(0.9),
                                ]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: 25, maxHeight: .infinity)
        }
    }

    var body: some View {
        VStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: .init(
                            colors: colorScheme == .dark
                                ? [darkBaseColor, .black]
                                : [lightBaseColor, .white]),
                        startPoint: .init(x: 0, y: 0),
                        endPoint: .init(x: 0, y: 1)
                    )
                )
                .overlay(
                    makeOverlay()
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.blue, lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.1),
                    radius: 2, x: 0, y: 2
                )

            VStack(spacing: 4.0) {
                Text(title).foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20.0)
                    .frame(maxWidth: 250.0)
            }
        }
        .contentShape(Rectangle())
    }
}
