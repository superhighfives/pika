import Defaults
import SwiftUI

struct Footer: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        @Default(.contrastStandard) var contrastStandard
        let colorContrastRatio = contrastStandard == .wcag ? foreground.color.toContrastRatioString(with: background.color) :
            foreground.color.APCAcontrastValue(with: background.color)
        let complianceType = contrastStandard == .wcag ? "WCAG" : "APCA"
        let colorCompliance: Any = contrastStandard == .wcag ?
            foreground.color.toWCAGCompliance(with: background.color) as Any :
            foreground.color.toAPCACompliance(with: background.color) as Any
        let contrastHeader = contrastStandard == .wcag ? PikaText.textColorRatio : PikaText.textLightnessContrastValue

        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(contrastHeader)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .fixedSize()
                Text("\(colorContrastRatio)")
                    .font(.system(size: 18))
                    .fixedSize()
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text(contrastStandard == .wcag ? PikaText.textColorWCAG : PikaText.textColorAPCA)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ComplianceToggleGroup(
                    colorCompliance: colorCompliance,
                    complianceType: complianceType,
                    theme: combineCompliance ? .contrast : .weight
                )
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
            .frame(width: 420.0)
    }
}
