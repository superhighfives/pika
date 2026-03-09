import Defaults
import SwiftUI

enum ComplianceData {
    case wcag(NSColor.WCAG)
    case apca(NSColor.APCA)
}

struct ComplianceToggleGroup: View {
    var complianceData: ComplianceData
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
        switch complianceData {
        case let .wcag(wcag):
            if theme == .weight {
                HStack(spacing: size == .full ? 16.0 : 8.0) {
                    HStack(alignment: .center, spacing: 8.0) {
                        if size == .full {
                            Text(PikaText.textColorNormal)
                                .fontWeight(.semibold)
                                .foregroundColor((wcag.ratio45 && wcag.ratio70) ? .primary : .secondary)
                                .fixedSize()
                        }
                        ComplianceToggle(title: "AA", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45, size: size)
                        ComplianceToggle(title: "AAA", isCompliant: wcag.ratio70, tooltip: PikaText.textColorWCAG70, size: size)
                    }
                    HStack(alignment: .center, spacing: 8.0) {
                        if size == .full {
                            Text(PikaText.textColorLarge)
                                .fontWeight(.semibold)
                                .foregroundColor((wcag.ratio30 && wcag.ratio45) ? .primary : .secondary)
                                .fixedSize()
                        }
                        ComplianceToggle(title: "AA", isCompliant: wcag.ratio30, tooltip: PikaText.textColorWCAG30, large: true, size: size)
                        ComplianceToggle(title: "AAA", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45, large: true, size: size)
                    }
                }
            } else {
                HStack(spacing: size == .full ? 16.0 : 8.0) {
                    ComplianceToggle(title: "AA", isCompliant: wcag.ratio30, tooltip: PikaText.textColorWCAG30, large: true, combined: true, size: size)
                    ComplianceToggle(title: "AA/AAA", isCompliant: wcag.ratio45, tooltip: PikaText.textColorWCAG45, large: true, combined: true, size: size)
                    ComplianceToggle(title: "AAA", isCompliant: wcag.ratio70, tooltip: PikaText.textColorWCAG70, combined: true, size: size)
                }
            }

        case let .apca(apca):
            HStack(spacing: size == .full ? 16.0 : 8.0) {
                ComplianceToggle(title: PikaText.textAPCABaseline, isCompliant: abs(apca.value) >= 30, tooltip: PikaText.textColorAPCA30, combined: true, size: size)
                ComplianceToggle(title: PikaText.textAPCAHeadline, isCompliant: abs(apca.value) >= 45, tooltip: PikaText.textColorAPCA45, combined: true, size: size)
                ComplianceToggle(title: PikaText.textAPCATitle, isCompliant: abs(apca.value) >= 60, tooltip: PikaText.textColorAPCA60, combined: true, size: size)
                ComplianceToggle(title: PikaText.textAPCABody, isCompliant: abs(apca.value) >= 75, tooltip: PikaText.textColorAPCA75, combined: true, size: size)
            }
        }
    }
}

struct ComplianceToggleGroup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let wcag = NSColor.white.WCAGCompliance(with: NSColor.red)
            ComplianceToggleGroup(complianceData: .wcag(wcag), theme: .contrast)
                .frame(width: 200, height: 18)

            let apca = NSColor.white.APCACompliance(with: NSColor.red)
            ComplianceToggleGroup(complianceData: .apca(apca), theme: .contrast)
                .frame(width: 200, height: 18)
        }
    }
}
