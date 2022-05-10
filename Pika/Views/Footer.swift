import SwiftUI

struct Footer: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(PikaText.textColorRatio)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Text("\(colorContrastRatio)")
                    .font(.system(size: 18))
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text(PikaText.textColorWCAG)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50.0, alignment: .leading)
        .padding(.horizontal, 12.0)
        .background(VisualEffect(
            material: NSVisualEffectView.Material.underWindowBackground,
            blendingMode: NSVisualEffectView.BlendingMode.behindWindow
        ))
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        let foreground = Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!)
        let background = Eyedropper(type: .background, color: NSColor.black)
        Footer(foreground: foreground, background: background)
    }
}
