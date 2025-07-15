import Defaults
import SwiftUI

struct ComplianceToggleGroup: View {
    var colorWCAGCompliance: NSColor.WCAG
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
        if theme == .weight {
            HStack(spacing: 16.0) {
                HStack(alignment: .center, spacing: 10.0) {
                    if size == .full {
                        Text(PikaText.textColorNormal)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                (colorWCAGCompliance.ratio45 && colorWCAGCompliance.ratio70)
                                    ? .primary
                                    : .secondary)
                            .fixedSize()
                    }

                    ComplianceToggle(
                        title: "AA",
                        isCompliant: colorWCAGCompliance.ratio45,
                        tooltip: PikaText.textColorWCAG45,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AAA",
                        isCompliant: colorWCAGCompliance.ratio70,
                        tooltip: PikaText.textColorWCAG70,
                        size: size
                    )
                }
                HStack(alignment: .center, spacing: 10.0) {
                    if size == .full {
                        Text(PikaText.textColorLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                (colorWCAGCompliance.ratio30 && colorWCAGCompliance.ratio45)
                                    ? .primary
                                    : .secondary)
                            .fixedSize()
                    }

                    ComplianceToggle(
                        title: "AA",
                        isCompliant: colorWCAGCompliance.ratio30,
                        tooltip: PikaText.textColorWCAG30,
                        large: true,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AAA",
                        isCompliant: colorWCAGCompliance.ratio45,
                        tooltip: PikaText.textColorWCAG45,
                        large: true,
                        size: size
                    )
                }
            }
        }

        if theme == .contrast {
            HStack(spacing: 16.0) {
                ComplianceToggle(
                    title: "AA",
                    isCompliant: colorWCAGCompliance.ratio30,
                    tooltip: NSLocalizedString("color.wcag.30", comment: "WCAG 3:1"),
                    large: true,
                    combined: true,
                    size: size
                )
                ComplianceToggle(
                    title: "AA/AAA",
                    isCompliant: colorWCAGCompliance.ratio45,
                    tooltip: NSLocalizedString("color.wcag.45", comment: "WCAG 4.5:1"),
                    large: true,
                    combined: true,
                    size: size
                )
                ComplianceToggle(
                    title: "AAA",
                    isCompliant: colorWCAGCompliance.ratio70,
                    tooltip: NSLocalizedString("color.wcag.70", comment: "WCAG 7:1"),

                    combined: true,
                    size: size
                )
            }
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        let colorWCAGCompliance = NSColor.white.WCAGCompliance(with: NSColor.red)
        ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance, theme: .contrast)
            .frame(width: 200, height: 18)
    }
}
