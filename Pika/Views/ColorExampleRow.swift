import SwiftUI

struct ColorExampleRow: View {
    var copyFormat: CopyFormat
    @ObservedObject var eyedropper: Eyedropper
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        let shadowColor: Color = eyedropper.color.getUIColor()

        HStack(alignment: .center, spacing: 8.0) {
            Circle()
                .fill(Color(eyedropper.color))
                .shadow(color: Color(eyedropper.color).opacity(0.25), radius: 1, x: 0, y: 1)
                .overlay(
                    Circle()
                        .stroke(shadowColor.opacity(0.25), lineWidth: 1)
                )

                .frame(width: 6, height: 6)
            HStack(alignment: .bottom, spacing: 4.0) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    HStack(alignment: .bottom, spacing: 2.0) {
                        Text(value.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(.primary)

                        Text(value.getExample(color: eyedropper.color, style: copyFormat))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fixedSize()
        }
    }
}

struct ColorExampleRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorExampleRow(copyFormat: CopyFormat.css, eyedropper: Eyedroppers().foreground)
    }
}
