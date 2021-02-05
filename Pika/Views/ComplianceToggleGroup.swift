import SwiftUI

struct ComplianceToggleGroup: View {
    var colorWCAGCompliance: NSColor.WCAG

    var body: some View {
        HStack(spacing: 8.0) {
            ComplianceToggle(title: "AA", isCompliant: self.colorWCAGCompliance.level2A,
                             tooltip: PikaConstants.AAText)
            ComplianceToggle(title: "AA+", isCompliant: self.colorWCAGCompliance.level2ALarge,
                             tooltip: PikaConstants.AAPlusText)
            ComplianceToggle(title: "AAA", isCompliant: self.colorWCAGCompliance.level3A,
                             tooltip: PikaConstants.AAAText)
            ComplianceToggle(title: "AAA+", isCompliant: self.colorWCAGCompliance.level3ALarge,
                             tooltip: PikaConstants.AAAPlusText)
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        let colorWCAGCompliance = NSColor.white.WCAGCompliance(with: NSColor.black)
        ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance)
    }
}
