import Defaults
import SwiftUI

struct CompliancePreviewWCAG: View {
    @Default(.combineCompliance) var combineCompliance
    var width: CGFloat
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let colorWCAGCompliance = foreground.color.toWCAGCompliance(
            with: background.color
        )

        Button(
            action: {
                combineCompliance = false
            },
            label: {
                ComplianceToggleGroup(
                    colorCompliance: colorWCAGCompliance,
                    complianceType: "WCAG", theme: .weight
                )
                .padding(20.0)
                .frame(
                    maxWidth: width, maxHeight: .infinity, alignment: .leading
                )
            }
        )
        .buttonStyle(
            AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: combineCompliance == false
            ))

        Button(
            action: {
                combineCompliance = true
            },
            label: {
                ComplianceToggleGroup(
                    colorCompliance: colorWCAGCompliance,
                    complianceType: "WCAG", theme: .contrast
                )
                .padding(20.0)
                .frame(
                    maxWidth: width, maxHeight: .infinity, alignment: .leading
                )
            }
        )
        .buttonStyle(
            AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: combineCompliance == true
            ))
    }
}

struct CompliancePreviewAPCA: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let colorAPCACompliance = foreground.color.toAPCACompliance(
            with: background.color
        )

        StyledContentView(title: PikaText.textAppearanceAPCATitle, description: PikaText.textAppearanceAPCADescription) {
            ComplianceToggleGroup(
                colorCompliance: colorAPCACompliance,
                complianceType: "APCA",
                theme: .weight
            )
            .padding(20.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct ComplianceButtons_Previews: PreviewProvider {
    static var previews: some View {
        let foreground = Eyedropper(
            type: .foreground,
            color: PikaConstants.initialColors.randomElement()!
        )
        let background = Eyedropper(type: .background, color: NSColor.black)
        CompliancePreviewWCAG(
            width: 200, foreground: foreground, background: background
        )
    }
}
