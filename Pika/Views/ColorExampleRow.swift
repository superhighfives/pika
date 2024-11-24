import SwiftUI

struct ColorExampleRow: View {
    var copyFormat: CopyFormat
    @ObservedObject var eyedropper: Eyedropper
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        let shadowColor: Color = eyedropper.color.getUIColor()

        HStack(alignment: .center, spacing: 8.0) {
            RoundedRectangle(cornerRadius: 2.0)
                .fill(Color(eyedropper.color))
                .shadow(color: Color(eyedropper.color).opacity(0.15), radius: 1, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 4.0)
                        .stroke(colorScheme == .dark ? .black : .white, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4.0)
                        .strokeBorder(shadowColor.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 12.0, height: 12.0)
            Text("\(PikaText.textCopyExportExample):").fixedSize().foregroundColor(.secondary)
                .font(.system(size: 11))

            HStack(alignment: .bottom, spacing: 8.0) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    HStack(alignment: .bottom, spacing: 4.0) {
                        Text(value.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)

                        Text(value.getExample(color: eyedropper.color, style: copyFormat))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 8.0)
        .padding(.vertical, 8.0)
        .frame(maxWidth: 460.0, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 4.0))
        .background(RoundedRectangle(cornerRadius: 4.0).fill(colorScheme == .dark
                ? .black.opacity(0.1)
                : .white.opacity(0.2))
        )
        .overlay(RoundedRectangle(cornerRadius: 4.0).stroke(Color.primary.opacity(0.1)))
    }
}

struct ColorExampleRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorExampleRow(copyFormat: CopyFormat.css, eyedropper: Eyedroppers().foreground)
    }
}
