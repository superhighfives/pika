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

private struct CompactBadge: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String

    var body: some View {
        HStack(alignment: .center, spacing: 2.0) {
            IconImage(name: isCompliant ? "checkmark.circle.fill" : "xmark.circle", resizable: true)
                .frame(width: 12.0, height: 12.0)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .fixedSize()
        }
        .foregroundColor(isCompliant ? .primary : .secondary.opacity(0.5))
        .help(tooltip)
    }
}

private struct CompactBothFooter: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let wcag = foreground.color.toWCAGCompliance(with: background.color)
        let apca = foreground.color.toAPCACompliance(with: background.color)

        VStack(alignment: .leading, spacing: 4.0) {
            HStack(spacing: 6.0) {
                Text("WCAG")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .fixedSize()

                HStack(spacing: 2.0) {
                    Text(foreground.color.toLocalizedContrastRatioString(with: background.color))
                        .font(.system(size: 13, weight: .medium))
                        .fixedSize()
                    HStack(spacing: 1.0) {
                        Text(":")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .fixedSize()
                        Text("1")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .fixedSize()
                    }
                }
                .help(PikaText.textColorRatioDescription)

                Spacer()

                if combineCompliance {
                    HStack(spacing: 10.0) {
                        CompactBadge(title: "AA LG", isCompliant: wcag.ratio30, tooltip: PikaText.textColorWCAG30)
                        CompactBadge(title: "AA/AAA LG", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45)
                        CompactBadge(title: "AAA", isCompliant: wcag.ratio70, tooltip: PikaText.textColorWCAG70)
                    }
                } else {
                    HStack(spacing: 10.0) {
                        CompactBadge(title: "AA", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45)
                        CompactBadge(title: "AAA", isCompliant: wcag.ratio70, tooltip: PikaText.textColorWCAG70)
                        CompactBadge(title: "AA LG", isCompliant: wcag.ratio30, tooltip: PikaText.textColorWCAG30)
                        CompactBadge(title: "AAA LG", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45)
                    }
                }
            }

            Divider()
                .padding(.horizontal, -12.0)

            HStack(spacing: 6.0) {
                Text("APCA")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .fixedSize()

                Text(foreground.color.toAPCAcontrastValue(with: background.color))
                    .font(.system(size: 13, weight: .medium))
                    .help(PikaText.textLightnessContrastValueDescription)
                    .fixedSize()

                Spacer()

                HStack(spacing: 10.0) {
                    CompactBadge(title: PikaText.textAPCABaseline, isCompliant: abs(apca.value) >= 30, tooltip: PikaText.textColorAPCA30)
                    CompactBadge(title: PikaText.textAPCAHeadline, isCompliant: abs(apca.value) >= 45, tooltip: PikaText.textColorAPCA45)
                    CompactBadge(title: PikaText.textAPCATitle, isCompliant: abs(apca.value) >= 60, tooltip: PikaText.textColorAPCA60)
                    CompactBadge(title: PikaText.textAPCABody, isCompliant: abs(apca.value) >= 75, tooltip: PikaText.textColorAPCA75)
                }
            }
        }
        .padding(.vertical, 6.0)
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
                CompactBothFooter(
                    foreground: foreground,
                    background: background
                )
                .frame(maxHeight: 50.0)
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
