import SwiftUI

struct ComplianceToggleGroup: View {
    var colorWCAGCompliance: NSColor.WCAG
    var size = Sizes.full
    enum Sizes: String, Codable, CaseIterable {
        case small
        case full
    }

    var body: some View {
        HStack(spacing: 12.0) {
            ComplianceToggle(
                title: "AA",
                isCompliant: self.colorWCAGCompliance.ratio30,
                tooltip: NSLocalizedString("color.wcag.30", comment: "WCAG 3:1"),
                large: true,
                size: size
            )
            ComplianceToggle(
                title: "AA/AAA",
                isCompliant: self.colorWCAGCompliance.ratio45,
                tooltip: NSLocalizedString("color.wcag.45", comment: "WCAG 4.5:1"),
                large: true,
                size: size
            )
            ComplianceToggle(
                title: "AAA",
                isCompliant: self.colorWCAGCompliance.ratio70,
                tooltip: NSLocalizedString("color.wcag.70", comment: "WCAG 7:1"),
                size: size
            )
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        let colorWCAGCompliance = NSColor.white.WCAGCompliance(with: NSColor.black)
        ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance)
    }
}
