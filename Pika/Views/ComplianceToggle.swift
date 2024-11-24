import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String
    var large: Bool = false
    var combined: Bool = false
    var size: ComplianceToggleGroup.Sizes

    var body: some View {
        HStack(alignment: .center, spacing: 2.0) {
            IconImage(name: isCompliant ? "checkmark.circle.fill" : "xmark.circle", resizable: true)
                .frame(width: size == .small ? 13.0 : 14.0, height: size == .small ? 13.0 : 14.0)
            Text(title)
                .fixedSize()

            if combined {
                if large {
                    Text(size == .small
                        ? NSLocalizedString("color.wcag.large.abbr", comment: "LG")
                        : NSLocalizedString("color.wcag.large", comment: "Large")
                    ).modify {
                        if size == .small {
                            $0
                                .fixedSize()
                                .font(.system(size: 10.0))
                                .padding(.bottom, 2.0)
                        } else {
                            $0
                        }
                    }
                }
            } else {
                if large, size == .small {
                    Text(PikaText.textColorLargeAbbr)
                        .fixedSize()
                        .font(.system(size: 10.0))
                        .padding(.bottom, 2.0)
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
        .fixedSize()
    }
}

struct ComplianceToggle_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceToggle(title: "AA", isCompliant: true, tooltip: "Help text", size: .full)
    }
}
