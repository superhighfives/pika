import SwiftUI

struct Footer: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    let AAText = "WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1 for normal text."
    let AAPlusText = "WCAG 2.0 level AA requires a contrast ratio of at least 3:1 for large text."
    let AAAText = "WCAG 2.0 level AAA requires a contrast ratio of at least 7:1 for normal text."
    let AAAPlusText = "WCAG 2.0 level AAA requires a contrast ratio of at least 4.5:1 for large text."

    var body: some View {
        let colorWCAGCompliance = eyedroppers.foreground.color.WCAGCompliance(with: eyedroppers.background.color)
        let colorContrastRatio = Double(round(100 * eyedroppers.foreground.color.contrastRatio(with: eyedroppers.background.color)) / 100).description

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
                                     tooltip: AAText)
                    ComplianceToggle(title: "AA+", isCompliant: colorWCAGCompliance.level2ALarge,
                                     tooltip: AAPlusText)
                    ComplianceToggle(title: "AAA", isCompliant: colorWCAGCompliance.level3A,
                                     tooltip: AAAText)
                    ComplianceToggle(title: "AAA+", isCompliant: colorWCAGCompliance.level3ALarge,
                                     tooltip: AAAPlusText)
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
        Footer()
            .environmentObject(Eyedroppers())
    }
}
