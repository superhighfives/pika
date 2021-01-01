//
//  EyedropperButtonStyle.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

// swiftlint:disable trailing_comma

import Defaults
import SwiftUI

let initialColors = [
    NSColor(r: 143.0, g: 15.0, b: 208.0),
    NSColor(r: 224.0, g: 53.0, b: 139.0),
    NSColor(r: 20.0, g: 63.0, b: 245.0),
    NSColor(r: 235.0, g: 54.0, b: 75.0),
    NSColor(r: 182.0, g: 26.0, b: 129.0),
    NSColor(r: 88.0, g: 32.0, b: 228.0),
    NSColor(r: 191.0, g: 19.0, b: 186.0),
    NSColor(r: 119.0, g: 77.0, b: 178.0),
    NSColor(r: 14.0, g: 35.0, b: 204.0),
    NSColor(r: 188.0, g: 42.0, b: 97.0),
]

struct ContentView: View {
    @ObservedObject var eyedropperForeground = Eyedropper(
        title: "Foreground", color: Color(initialColors.randomElement()!)
    )
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: .black)

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        let eyedroppers = [eyedropperForeground, eyedropperBackground]

        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            HStack(spacing: 0.0) {
                ForEach(eyedroppers, id: \.title) { eyedropper in
                    let textColor = eyedropper.color.luminance < 0.333 ? Color.white : Color.black

                    ZStack {
                        Button(action: { eyedropper.start() }, label: {
                            ZStack {
                                Group {
                                    Rectangle()
                                        .fill(Color(eyedropper.color.overlayBlack))
                                        .frame(height: 55.0)
                                }
                                .opacity(0.2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

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

                    Divider()
                }
            }
            .clipped()

            Divider()

            FooterView(foreground: self.$eyedropperForeground.color, background: self.$eyedropperBackground.color)
        }
        .onAppear {
            eyedropperBackground.set(color: NSColor(colorScheme == .light ? Color.white : .black))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
