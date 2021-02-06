import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String
    var large: Bool = false
    var size: ComplianceToggleGroup.Sizes

    var body: some View {
        HStack(spacing: 2.0) {
            IconImage(name: isCompliant ? "checkmark.circle.fill" : "xmark.circle")
            Text(title)
            if large {
                Text(size == .small ? "LG" : "Large")
                    .modify {
                        if size == .small {
                            $0.font(.system(size: 10.0))
                                .baselineOffset(4.0)
                        } else {
                            $0
                        }
                    }
            }
        }
        .opacity(isCompliant ? 1.0 : 0.4)
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
