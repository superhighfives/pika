import Defaults
import SwiftUI

protocol ColorCompliance {
    var complianceType: String { get }
}

extension NSColor.WCAG: ColorCompliance {
    var complianceType: String { "WCAG" }
}

extension NSColor.APCA: ColorCompliance {
    var complianceType: String { "APCA" }
}

struct ComplianceToggleGroup: View {
    var colorCompliance: Any
    var complianceType: String
    var size = Sizes.full
    var theme: Themes

    enum Themes: String, Codable, CaseIterable {
        case weight
        case contrast
    }

    enum Sizes: String, Codable, CaseIterable {
        case small
        case full
    }

    var body: some View {
        if complianceType == "WCAG", let wcag = colorCompliance as? NSColor.WCAG
        {
            if theme == .weight {
                HStack(spacing: 16.0) {
                    HStack(alignment: .center, spacing: 8.0) {
                        if size == .full {
                            Text(PikaText.textColorNormal)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    (wcag.ratio45 && wcag.ratio70)
                                        ? .primary
                                        : .secondary
                                )
                                .fixedSize()
                        }

                        ComplianceToggle(
                            title: "AA",
                            isCompliant: wcag.ratio45,
                            tooltip: PikaText.textColorWCAG45,
                            size: size
                        )
                        ComplianceToggle(
                            title: "AAA",
                            isCompliant: wcag.ratio70,
                            tooltip: PikaText.textColorWCAG70,
                            size: size
                        )
                    }
                    HStack(alignment: .center, spacing: 8.0) {
                        if size == .full {
                            Text(PikaText.textColorLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    (wcag.ratio30 && wcag.ratio45)
                                        ? .primary
                                        : .secondary
                                )
                                .fixedSize()
                        }

                        ComplianceToggle(
                            title: "AA",
                            isCompliant: wcag.ratio30,
                            tooltip: PikaText.textColorWCAG30,
                            large: true,
                            size: size
                        )
                        ComplianceToggle(
                            title: "AAA",
                            isCompliant: wcag.ratio45,
                            tooltip: PikaText.textColorWCAG45,
                            large: true,
                            size: size
                        )
                    }
                }
            } else if theme == .contrast,
                let wcag = colorCompliance as? NSColor.WCAG
            {
                HStack(spacing: 12.0) {
                    ComplianceToggle(
                        title: "AA",
                        isCompliant: wcag.ratio30,
                        tooltip: NSLocalizedString(
                            "color.wcag.30", comment: "WCAG 3:1"),
                        large: true,
                        combined: true,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AA/AAA",
                        isCompliant: wcag.ratio45,
                        tooltip: NSLocalizedString(
                            "color.wcag.45", comment: "WCAG 4.5:1"),
                        large: true,
                        combined: true,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AAA",
                        isCompliant: wcag.ratio70,
                        tooltip: NSLocalizedString(
                            "color.wcag.70", comment: "WCAG 7:1"),
                        combined: true,
                        size: size
                    )
                }
            }

        } else if complianceType == "APCA",
            let apca = colorCompliance as? NSColor.APCA
        {
            HStack(spacing: 12.0) {
                ComplianceToggle(
                    title: "Baseline",
                    isCompliant: abs(apca.value) >= 30,
                    tooltip: "APCA ≥45",
                    combined: true,
                    size: size
                )
                ComplianceToggle(
                    title: "Headline",
                    isCompliant: abs(apca.value) >= 45,
                    tooltip: "APCA ≥45",
                    combined: true,
                    size: size
                )
                ComplianceToggle(
                    title: "Title",
                    isCompliant: abs(apca.value) >= 60,
                    tooltip: "APCA ≥45",
                    combined: true,
                    size: size
                )
                ComplianceToggle(
                    title: "Body Text",
                    isCompliant: abs(apca.value) >= 75,
                    tooltip: "APCA ≥75",
                    combined: true,
                    size: size
                )
            }
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let wcag = NSColor.white.WCAGCompliance(with: NSColor.red)
            ComplianceToggleGroup(
                colorCompliance: wcag,
                complianceType: "WCAG",
                theme: .contrast
            )
            .frame(width: 200, height: 18)

            let apca = NSColor.white.APCACompliance(with: NSColor.red)
            ComplianceToggleGroup(
                colorCompliance: apca,
                complianceType: "APCA",
                theme: .contrast
            )
            .frame(width: 200, height: 18)
        }
    }
}
