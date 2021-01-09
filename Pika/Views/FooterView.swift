//
//  FooterView.swift
//  Pika
//
//  Created by Charlie Gleason on 31/12/2020.
//

import SwiftUI

struct FooterView: View {
    @Binding var foreground: NSColor
    @Binding var background: NSColor

    var body: some View {
        let colorWCAGCompliance = foreground.WCAGCompliance(with: background)
        let colorContrastRatio = Double(round(100 * foreground.contrastRatio(with: background)) / 100).description

        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 0.0) {
                Text("Contrast ratio")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                Text("\(colorContrastRatio)")
                    .font(.system(size: 18))
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text("WCAG Compliance")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                HStack(spacing: 6.0) {
                    // swiftlint:disable line_length
                    ComplianceToggle(title: "AA", isCompliant: colorWCAGCompliance.Level2A,
                                     tooltip: "WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1 for normal text.")
                    ComplianceToggle(title: "AA+", isCompliant: colorWCAGCompliance.Level2ALarge,
                                     tooltip: "WCAG 2.0 level AA requires a contrast ratio of at least 3:1 for large text.")
                    ComplianceToggle(title: "AAA", isCompliant: colorWCAGCompliance.Level3A,
                                     tooltip: "WCAG 2.0 level AAA requires a contrast ratio of at least 7:1 for normal text.")
                    ComplianceToggle(title: "AAA+", isCompliant: colorWCAGCompliance.Level3ALarge,
                                     tooltip: "WCAG 2.0 level AAA requires a contrast ratio of at least 4.5:1 for large text.")
                    // swiftlint:enable line_length
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50.0, alignment: .leading)
        .padding(.horizontal, 12.0)
    }
}

struct FooterView_Previews: PreviewProvider {
    private struct ViewWrapper: View {
        @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: NSColor.random())
        @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: NSColor.random())

        var body: some View {
            FooterView(foreground: self.$eyedropperForeground.color, background: self.$eyedropperBackground.color)
        }
    }

    static var previews: some View {
        ViewWrapper()
    }
}
