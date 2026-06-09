import Defaults
import SwiftUI

struct CompliancePreviewWCAG: View {
    @Default(.combineCompliance) var combineCompliance
    var width: CGFloat
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let wcag = foreground.color.toWCAGCompliance(with: background.color)

        HStack(spacing: 16.0) {
            Button(
                action: { combineCompliance = false },
                label: {
                    ComplianceToggleGroup(complianceData: .wcag(wcag), theme: .weight)
                        .padding(20.0)
                        .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
                }
            )
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: combineCompliance == false
            ))

            Button(
                action: { combineCompliance = true },
                label: {
                    ComplianceToggleGroup(complianceData: .wcag(wcag), theme: .contrast)
                        .padding(20.0)
                        .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
                }
            )
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: combineCompliance == true
            ))
        }
    }
}

struct CompliancePreviewAPCA: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let apca = foreground.color.toAPCACompliance(with: background.color)

        StyledContentView(
            title: PikaText.textAppearanceAPCATitle,
            description: PikaText.textAppearanceAPCADescription
        ) {
            ComplianceToggleGroup(complianceData: .apca(apca), theme: .weight)
                .padding(20.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct CompliancePreviewBoth: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let wcag = foreground.color.toWCAGCompliance(with: background.color)
        let apca = foreground.color.toAPCACompliance(with: background.color)

        HStack(spacing: 16.0) {
            Button(action: { combineCompliance = false }) {
                footerPreview(wcag: wcag, apca: apca, theme: .weight)
            }
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: combineCompliance == false
            ))

            Button(action: { combineCompliance = true }) {
                footerPreview(wcag: wcag, apca: apca, theme: .contrast)
            }
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: combineCompliance == true
            ))
        }
    }

    @ViewBuilder
    private func footerPreview(wcag: NSColor.WCAG, apca: NSColor.APCA, theme: ComplianceToggleGroup.Themes) -> some View {
        GeometryReader { geometry in
            let scale = min(1.0, geometry.size.width / 380)

            VStack(alignment: .leading, spacing: 4.0) {
                HStack(spacing: 0) {
                    Text("WCAG")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    HStack(spacing: 2.0) {
                        Text(foreground.color.toLocalizedContrastRatioString(with: background.color))
                            .font(.system(size: 13, weight: .medium))
                            .fixedSize()
                        Text(": 1")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .fixedSize()
                    }
                    Spacer()
                    ComplianceToggleGroup(complianceData: .wcag(wcag), size: .small, theme: theme)
                }

                Divider()

                HStack(spacing: 0) {
                    Text("APCA")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    Text(foreground.color.toAPCAcontrastValue(with: background.color))
                        .font(.system(size: 13, weight: .medium))
                        .fixedSize()
                    Spacer()
                    ComplianceToggleGroup(complianceData: .apca(apca), size: .small, theme: .weight)
                }
            }
            .padding(.horizontal, 10.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .scaleEffect(scale, anchor: .leading)
        }
    }
}

struct ComplianceButtons_Previews: PreviewProvider {
    static var previews: some View {
        let foreground = Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!)
        let background = Eyedropper(type: .background, color: NSColor.black)
        CompliancePreviewWCAG(width: 200, foreground: foreground, background: background)
    }
}
