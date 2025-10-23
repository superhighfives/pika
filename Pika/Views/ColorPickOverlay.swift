import SwiftUI

struct ColorPickOverlay: View {
    let colorText: String
    let pickedColor: NSColor

    var body: some View {
        Text(colorText)
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(pickedColor.getUIColor())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(pickedColor),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(pickedColor.getUIColor().opacity(0.2), lineWidth: 1)
            )
            .fixedSize(horizontal: true, vertical: true)
    }
}

struct ColorPickOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ColorPickOverlay(colorText: "#232323", pickedColor: NSColor(hex: "#232323"))
            ColorPickOverlay(colorText: "rgb(35, 35, 35)", pickedColor: NSColor(hex: "#232323"))
            ColorPickOverlay(colorText: "hsl(0, 0%, 14%)", pickedColor: NSColor(hex: "#232323"))
            ColorPickOverlay(colorText: "0.14 0.14 0.14", pickedColor: NSColor(hex: "#232323"))
        }
        .frame(width: 400, height: 400)
    }
}
