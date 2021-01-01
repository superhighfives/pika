//
//  EyedropperButtonStyle.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Defaults
import SwiftUI

struct ColorNavigation: View {
    var eyedropper: Eyedropper
    let pasteboard = NSPasteboard.general

    var body: some View {
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
}

struct ContentView: View {
    @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: Color(NSColor.random()))

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let eyedroppers = [eyedropperForeground, eyedropperBackground]

        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            HStack(spacing: 0.0) {
                ForEach(eyedroppers, id: \.title) { eyedropper in
                    let textColor = eyedropper.color.luminance < 0.333 ? Color.white : Color.black

                    ZStack {
                        Button(action: { eyedropper.start() }, label: {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text(eyedropper.title)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(textColor.opacity(0.5))
                                    HStack {
                                        Text(eyedropper.color.toFormat(format: colorFormat))
                                            .foregroundColor(textColor)
                                            .font(.title2)
                                        Image(systemName: "eyedropper")
                                            .foregroundColor(textColor)
                                            .padding(.leading, 0.0)
                                            .opacity(0.8)
                                    }
                                }
                                .padding([.bottom, .leading], 8.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            }
                        })
                            .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
                            .contextMenu {
                                ColorNavigation(eyedropper: eyedropper)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Menu {
                            ColorNavigation(eyedropper: eyedropper)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .shadow(radius: 0, x: 0, y: 1)
                        .opacity(0.8)
                        .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
                        .fixedSize()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(8.0)
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
            .clipped()

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
