//
//  EyedropperButtonStyle.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: Color(NSColor.random()))

    let pasteboard = NSPasteboard.general

    var body: some View {
        let eyedroppers = [eyedropperForeground, eyedropperBackground]
        let colorWCAGCompliance = eyedropperForeground.color.WCAGCompliance(with: eyedropperBackground.color)
        
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            HStack(spacing: 0.0) {
                Divider()
                ForEach(eyedroppers, id: \.title) { eyedropper in
                    let textColor = eyedropper.color.isDark ? Color.white : Color.black
                    Button(action: { eyedropper.start() }, label: {
                        VStack(alignment: .leading) {
                            Text(eyedropper.title)
                                .font(.caption)
                                .bold()
                                .foregroundColor(textColor.opacity(0.5))
                            Text("Lol")
//                            Text(eyedropper.color.toHex)
//                                .foregroundColor(textColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    })
                        .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
                        .contextMenu {
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toHex, forType: .string)
                            }, label: { Text("Copy color hex") })
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toHex, forType: .string)
                            }, label: { Text("Copy RGBA values") })
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toHex, forType: .string)
                            }, label: { Text("Copy HSB values") })
                        }
                    Divider()
                }
            }

            Divider()

            HStack(spacing: 16.0) {
                VStack(alignment: .leading) {
                    Text("Contrast ratio")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.gray)
                    Text(Double(round(
                        100 * eyedropperForeground.color.contrastRatio(with: eyedropperBackground.color)) / 100
                    ).description)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("WCAG 2.0")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.gray)
                    HStack(spacing: 5.0) {
                        HStack(spacing: 1.0) {
                            Image(systemName: colorWCAGCompliance.Level2A ? "checkmark" : "xmark")
                            Text("AA")
                        }
                        .opacity(colorWCAGCompliance.Level2A ? 1.0 : 0.5)
                        HStack(spacing: 1.0) {
                            Image(systemName: colorWCAGCompliance.Level2ALarge ? "checkmark" : "xmark")
                            Text("AA+")
                        }
                        .opacity(colorWCAGCompliance.Level2ALarge ? 1.0 : 0.5)
                        HStack(spacing: 1.0) {
                            Image(systemName: colorWCAGCompliance.Level3A ? "checkmark" : "xmark")
                            Text("AAA")
                        }
                        .opacity(colorWCAGCompliance.Level3A ? 1.0 : 0.5)
                        HStack(spacing: 1.0) {
                            Image(systemName: colorWCAGCompliance.Level3ALarge ? "checkmark" : "xmark")
                            Text("AAA+")
                        }
                        .opacity(colorWCAGCompliance.Level3ALarge ? 1.0 : 0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 50.0, alignment: .leading)
            .padding(.horizontal, 16.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
