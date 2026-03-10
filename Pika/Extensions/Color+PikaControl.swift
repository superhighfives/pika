import SwiftUI

extension Color {
    static func pikaControlBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 27 / 255, green: 27 / 255, blue: 27 / 255)
            : Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
    }
}
