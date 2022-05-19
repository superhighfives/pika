import SwiftUI

struct ComplianceToggleGroup: View {
    var colorWCAGCompliance: NSColor.WCAG
    var size = Sizes.full
    enum Sizes: String, Codable, CaseIterable {
        case small
        case full
    }

    var body: some View {
        HStack(spacing: 16.0) {
            HStack(alignment: .center, spacing: 8.0) {
                Text("Normal")
                    .foregroundColor(
                        (self.colorWCAGCompliance.ratio45 && self.colorWCAGCompliance.ratio70)
                            ? .primary
                            : .secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                    ComplianceToggle(
                        title: "AA",
                        isCompliant: self.colorWCAGCompliance.ratio45,
                        tooltip: PikaText.textColorWCAG45,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AAA",
                        isCompliant: self.colorWCAGCompliance.ratio70,
                        tooltip: PikaText.textColorWCAG70,
                        size: size
                    )
                }
            }

            HStack(alignment: .center, spacing: 8.0) {
                Text("Large")
                    .foregroundColor(
                        (self.colorWCAGCompliance.ratio30 && self.colorWCAGCompliance.ratio45)
                            ? .primary
                            : .secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                    ComplianceToggle(
                        title: "AA",
                        isCompliant: self.colorWCAGCompliance.ratio30,
                        tooltip: PikaText.textColorWCAG30,
                        size: size
                    )
                    ComplianceToggle(
                        title: "AAA",
                        isCompliant: self.colorWCAGCompliance.ratio45,
                        tooltip: PikaText.textColorWCAG45,

                        size: size
                    )
                }
            }
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        let colorWCAGCompliance = NSColor.white.WCAGCompliance(with: NSColor.red)
        ComplianceToggleGroup(colorWCAGCompliance: colorWCAGCompliance)
            .frame(width: 500, height: 18)
    }
}
