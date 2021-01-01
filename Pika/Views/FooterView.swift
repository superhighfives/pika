//
//  FooterView.swift
//  Pika
//
//  Created by Charlie Gleason on 31/12/2020.
//

import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool

    var body: some View {
        HStack(spacing: 2.0) {
            Image(systemName: isCompliant ? "checkmark.circle.fill" : "xmark.circle")
                .opacity(isCompliant ? 1.0 : 0.4)
            Text(title)
        }
        .opacity(isCompliant ? 1.0 : 0.4)
    }
}

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
                    .font(.title2)
            }

            Divider()

            VStack(alignment: .leading, spacing: 3.0) {
                Text("WCAG Compliance")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                HStack(spacing: 6.0) {
                    ComplianceToggle(title: "AA", isCompliant: colorWCAGCompliance.Level2A)
                    ComplianceToggle(title: "AA+", isCompliant: colorWCAGCompliance.Level2ALarge)
                    ComplianceToggle(title: "AAA", isCompliant: colorWCAGCompliance.Level3A)
                    ComplianceToggle(title: "AAA+", isCompliant: colorWCAGCompliance.Level3ALarge)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50.0, alignment: .leading)
        .padding(.horizontal, 12.0)
    }
}

struct FooterView_Previews: PreviewProvider {
    private struct ViewWrapper: View {
        @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
        @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: Color(NSColor.random()))

        var body: some View {
            FooterView(foreground: self.$eyedropperForeground.color, background: self.$eyedropperBackground.color)
        }
    }

    static var previews: some View {
        ViewWrapper()
    }
}
