import SwiftUI

struct Footer: View {
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)
        let colorContrastRatio = foreground.color.toContrastRatioString(with: background.color)

        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text("Contrast ratio")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                Text("\(colorContrastRatio)")
                    .font(.system(size: 18))
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text("WCAG Compliance")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                HStack(spacing: 6.0) {
                    ComplianceToggle(title: "AA", isCompliant: colorWCAGCompliance.level2A,
                                     tooltip: PikaConstants.AAText)
                    ComplianceToggle(title: "AA+", isCompliant: colorWCAGCompliance.level2ALarge,
                                     tooltip: PikaConstants.AAPlusText)
                    ComplianceToggle(title: "AAA", isCompliant: colorWCAGCompliance.level3A,
                                     tooltip: PikaConstants.AAAText)
                    ComplianceToggle(title: "AAA+", isCompliant: colorWCAGCompliance.level3ALarge,
                                     tooltip: PikaConstants.AAAPlusText)
                }
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
        let foreground = Eyedropper(
            title: "Foreground", color: PikaConstants.initialColors.randomElement()!
        )
        let background = Eyedropper(title: "Background", color: NSColor.black)
        Footer(foreground: foreground, background: background)
    }
}
