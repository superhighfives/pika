import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String
    var large: Bool = false
    var size: ComplianceToggleGroup.Sizes

    var body: some View {
        HStack(spacing: 2.0) {
            Image(systemName: isCompliant ? "checkmark.circle.fill" : "xmark.circle")
            Text(title)

            if large {
                Text(size == .small
                    ? NSLocalizedString("touchbar.wcag.large.abbr", comment: "LG")
                    : NSLocalizedString("touchbar.wcag.large", comment: "Large")
                ).modify {
                    if size == .small {
                        $0.font(.system(size: 10.0))
                            .baselineOffset(4.0)
                    } else {
                        $0
                    }
                }
            }
        }
        .opacity(isCompliant ? 1.0 : 0.5)
        .help(tooltip)
    }
}

struct ComplianceToggle_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceToggle(title: "AA", isCompliant: true, tooltip: "Help text", size: .full)
    }
}
