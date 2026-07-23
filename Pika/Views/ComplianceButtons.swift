import Defaults
import SwiftUI

private struct NaturalWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Renders `content` at its natural (untruncated) width, then uniformly scales it down to
/// fit the available width. The preview tiles are narrower than the full compliance badges
/// need, and laying the badges out at the tile width just truncates them ("AA…La…"); this
/// keeps them whole and legible by shrinking instead.
private struct ScaleToFitWidth<Content: View>: View {
    var alignment: Alignment = .leading
    @ViewBuilder var content: Content
    @State private var naturalWidth: CGFloat = 0

    private var anchor: UnitPoint { alignment == .center ? .center : .leading }

    var body: some View {
        GeometryReader { geo in
            let scale = naturalWidth > 0 ? min(1, geo.size.width / naturalWidth) : 1
            content
                .fixedSize()
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: NaturalWidthKey.self, value: proxy.size.width)
                    }
                )
                .scaleEffect(scale, anchor: anchor)
                .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
        }
        .onPreferenceChange(NaturalWidthKey.self) { naturalWidth = $0 }
    }
}

struct CompliancePreviewWCAG: View {
    @Default(.combineCompliance) var combineCompliance
    var width: CGFloat
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let wcag = foreground.color.toWCAGCompliance(with: background.color)

        HStack(spacing: 16.0) {
            Button(
                action: { combineCompliance = false },
                label: {
                    ScaleToFitWidth {
                        ComplianceToggleGroup(complianceData: .wcag(wcag), theme: .weight)
                            .padding(20.0)
                    }
                    .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
                }
            )
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: combineCompliance == false
            ))

            Button(
                action: { combineCompliance = true },
                label: {
                    ScaleToFitWidth {
                        ComplianceToggleGroup(complianceData: .wcag(wcag), theme: .contrast)
                            .padding(20.0)
                    }
                    .frame(maxWidth: width, maxHeight: .infinity, alignment: .leading)
                }
            )
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: combineCompliance == true
            ))
        }
    }
}

struct CompliancePreviewAPCA: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let apca = foreground.color.toAPCACompliance(with: background.color)

        StyledContentView(
            title: PikaText.textAppearanceAPCATitle,
            description: PikaText.textAppearanceAPCADescription
        ) {
            ScaleToFitWidth(alignment: .center) {
                ComplianceToggleGroup(complianceData: .apca(apca), theme: .weight)
                    .padding(20.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct CompliancePreviewBoth: View {
    @Default(.combineCompliance) var combineCompliance
    @ObservedObject var foreground: Eyedropper
    @ObservedObject var background: Eyedropper

    var body: some View {
        let wcag = foreground.color.toWCAGCompliance(with: background.color)
        let apca = foreground.color.toAPCACompliance(with: background.color)

        HStack(spacing: 16.0) {
            Button(action: { combineCompliance = false }) {
                footerPreview(wcag: wcag, apca: apca, theme: .weight)
            }
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceWeightTitle,
                description: PikaText.textAppearanceWeightDescription,
                selected: combineCompliance == false
            ))

            Button(action: { combineCompliance = true }) {
                footerPreview(wcag: wcag, apca: apca, theme: .contrast)
            }
            .buttonStyle(AppearanceButtonStyle(
                title: PikaText.textAppearanceContrastTitle,
                description: PikaText.textAppearanceContrastDescription,
                selected: combineCompliance == true
            ))
        }
    }

    @ViewBuilder
    private func footerPreview(wcag: NSColor.WCAG, apca: NSColor.APCA, theme: ComplianceToggleGroup.Themes) -> some View {
        GeometryReader { geometry in
            // Lay the row out at its full natural width so the Spacer-aligned badges keep
            // their real size, then scale the whole thing down to the tile — otherwise the
            // badges compress and truncate at the tile width before the scale is applied.
            let reference: CGFloat = 430
            let scale = min(1.0, geometry.size.width / reference)

            VStack(alignment: .leading, spacing: 4.0) {
                HStack(spacing: 0) {
                    Text("WCAG")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                    HStack(spacing: 2.0) {
                        Text(foreground.color.toLocalizedContrastRatioString(with: background.color))
                            .font(.system(size: 13, weight: .medium))
                            .fixedSize()
                        Text(": 1")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .fixedSize()
                    }
                    Spacer()
                    ComplianceToggleGroup(complianceData: .wcag(wcag), size: .small, theme: theme)
                }

                Divider()

                HStack(spacing: 0) {
                    Text("APCA")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .leading)
                    Text(foreground.color.toAPCAcontrastValue(with: background.color))
                        .font(.system(size: 13, weight: .medium))
                        .fixedSize()
                    Spacer()
                    ComplianceToggleGroup(complianceData: .apca(apca), size: .small, theme: .weight)
                }
            }
            .padding(.horizontal, 10.0)
            .frame(width: reference, alignment: .leading)
            .scaleEffect(scale, anchor: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct ComplianceButtons_Previews: PreviewProvider {
    static var previews: some View {
        let foreground = Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!)
        let background = Eyedropper(type: .background, color: NSColor.black)
        CompliancePreviewWCAG(width: 200, foreground: foreground, background: background)
    }
}
