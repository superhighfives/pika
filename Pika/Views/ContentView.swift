//
//  EyedropperButtonStyle.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Defaults
import SwiftUI

struct ContentView: View {
    @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: Color(NSColor.random()))

    @Default(.colorFormat) var colorFormat

    let pasteboard = NSPasteboard.general

    var body: some View {
        let eyedroppers = [eyedropperForeground, eyedropperBackground]

        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            HStack(spacing: 0.0) {
                ForEach(eyedroppers, id: \.title) { eyedropper in
                    let textColor = eyedropper.color.luminance < 0.333 ? Color.white : Color.black
                    Button(action: { eyedropper.start() }, label: {
                        VStack(alignment: .leading) {
                            Text(eyedropper.title)
                                .font(.caption)
                                .bold()
                                .foregroundColor(textColor.opacity(0.5))
                            Text(eyedropper.color.toFormat(format: colorFormat))
                                .foregroundColor(textColor)
                                .font(.title2)
                        }
                        .padding(10.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    })
                        .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
                        .contextMenu {
                            Text(eyedropper.title)
                            Divider()
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toHex, forType: .string)
                            }, label: { Text("Copy color hex") })
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toRGB, forType: .string)
                            }, label: { Text("Copy RGB values") })
                            Button(action: {
                                pasteboard.clearContents()
                                pasteboard.setString(eyedropper.color.toHSB, forType: .string)
                            }, label: { Text("Copy HSB values") })
                        }
                        .frame(maxWidth: .infinity)
                }

            }.shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)

            Divider()

            FooterView(foreground: self.$eyedropperForeground.color, background: self.$eyedropperBackground.color)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
