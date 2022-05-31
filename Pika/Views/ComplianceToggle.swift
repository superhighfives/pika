import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String
    var large: Bool = false
    var combined: Bool = false
    var size: ComplianceToggleGroup.Sizes

    var body: some View {
        HStack(spacing: 2.0) {
            IconImage(name: isCompliant ? "checkmark.circle.fill" : "xmark.circle")
            Text(title)
                .fixedSize()

            if combined {
                if large {
                    Text(size == .small
                        ? NSLocalizedString("color.wcag.large.abbr", comment: "LG")
                        : NSLocalizedString("color.wcag.large", comment: "Large")
                    ).modify {
                        if size == .small {
                            $0.font(.system(size: 10.0))
                                .baselineOffset(4.0)
                        } else {
                            $0
                        }
                    }
                }
            } else {
                if large && size == .small {
                    Text(PikaText.textColorLargeAbbr)
                        .font(.system(size: 10.0))
                        .baselineOffset(4.0)
                }
            }
        }
        .foregroundColor(isCompliant ? .primary
            : .secondary)
        .modify {
            if #available(OSX 11.0, *) {
                $0.help(tooltip)
            } else {
                $0
            }
        }
    }
}

struct ComplianceToggle_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceToggle(title: "AA", isCompliant: true, tooltip: "Help text", size: .full)
    }
}
