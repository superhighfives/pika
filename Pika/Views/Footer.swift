import Defaults
import SwiftUI

private enum FooterRowKind {
    case wcag
    case apca
}

private struct FooterRow: View {
    let kind: FooterRowKind
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper
    var combineCompliance: Bool

    private var contrastHeader: String {
        kind == .wcag ? PikaText.textColorRatio : PikaText.textLightnessContrastValue
    }

    private var complianceLabel: String {
        kind == .wcag ? PikaText.textColorWCAG : PikaText.textColorAPCA
    }

    private var contrastRatioString: String {
        kind == .wcag
            ? foreground.color.toLocalizedContrastRatioString(with: background.color)
            : foreground.color.toAPCAcontrastValue(with: background.color)
    }

    private var complianceData: ComplianceData {
        kind == .wcag
            ? .wcag(foreground.color.toWCAGCompliance(with: background.color))
            : .apca(foreground.color.toAPCACompliance(with: background.color))
    }

    var body: some View {
        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(contrastHeader)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .fixedSize()
                if kind == .wcag {
                    HStack(spacing: 2.0) {
                        Text(contrastRatioString)
                            .font(.system(size: 18))
                            .help(PikaText.textColorRatioDescription)
                            .fixedSize()
                        HStack(spacing: 1.0) {
                            Text(":")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.secondary)
                                .fixedSize()
                            Text("1")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.secondary)
                                .fixedSize()
                        }
                    }
                } else {
                    Text(contrastRatioString)
                        .font(.system(size: 18))
                        .help(PikaText.textLightnessContrastValueDescription)
                        .fixedSize()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text(complianceLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ComplianceToggleGroup(
                    complianceData: complianceData,
                    theme: combineCompliance ? .contrast : .weight
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Footer: View {
    @Default(.combineCompliance) var combineCompliance
    @Default(.contrastStandard) var contrastStandard
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        Group {
            if contrastStandard == .both {
                VStack(alignment: .leading, spacing: 8.0) {
                    FooterRow(
                        kind: .wcag,
                        foreground: foreground,
                        background: background,
                        combineCompliance: combineCompliance
                    )
                    Divider()
                    FooterRow(
                        kind: .apca,
                        foreground: foreground,
                        background: background,
                        combineCompliance: combineCompliance
                    )
                }
                .padding(.vertical, 8.0)
            } else {
                FooterRow(
                    kind: contrastStandard == .wcag ? .wcag : .apca,
                    foreground: foreground,
                    background: background,
                    combineCompliance: combineCompliance
                )
                .frame(maxHeight: 50.0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
