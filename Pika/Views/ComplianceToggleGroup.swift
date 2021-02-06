import SwiftUI

struct ComplianceToggleGroup: View {
    var colorWCAGCompliance: NSColor.WCAG
    var size = Sizes.full
    enum Sizes: String, Codable, CaseIterable {
        case small
        case full
    }

    var body: some View {
        HStack(spacing: 10.0) {
            ComplianceToggle(
                title: "AA",
                isCompliant: self.colorWCAGCompliance.ratio30,
                tooltip: PikaConstants.ratio30,
                large: true,
                size: size
            )
            ComplianceToggle(
                title: "AA/AAA",
                isCompliant: self.colorWCAGCompliance.ratio45,
                tooltip: PikaConstants.ratio45,
                large: true,
                size: size
            )
            ComplianceToggle(
                title: "AAA",
                isCompliant: self.colorWCAGCompliance.ratio70,
                tooltip: PikaConstants.ratio70,
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
