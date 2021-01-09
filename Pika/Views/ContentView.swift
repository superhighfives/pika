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
        title: "Foreground", color: initialColors.randomElement()!
    )
    @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: NSColor.black)

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ViewBuilder
    func getMenu(eyedropper: Eyedropper) -> some View {
        if #available(OSX 11.0, *) {
            Menu {
                ColorNavigation(eyedropper: eyedropper)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
        } else {
            MenuButton(label: IconImage(name: "ellipsis.circle"), content: {
                ColorNavigation(eyedropper: eyedropper)
            })
                .menuButtonStyle(BorderlessButtonMenuButtonStyle())
        }
    }

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

                                VStack(alignment: .leading, spacing: 0.0) {
                                    Text(eyedropper.title)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(textColor.opacity(0.5))
                                    HStack {
                                        Text(eyedropper.color.toFormat(format: colorFormat))
                                            .foregroundColor(textColor)
                                            .font(.system(size: 18, weight: .regular))
                                        IconImage(name: "eyedropper")
                                            .foregroundColor(textColor)
                                            .padding(.leading, 0.0)
                                            .opacity(0.8)
                                    }
                                }
                                .padding([.bottom, .leading], 10.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            }

                        })
                            .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
                            .contextMenu {
                                ColorNavigation(eyedropper: eyedropper)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        getMenu(eyedropper: eyedropper)
                            .shadow(radius: 0, x: 0, y: 1)
                            .opacity(0.8)
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
            eyedropperBackground.set(color: colorScheme == .light
                ? NSColor(r: 255.0, g: 255.0, b: 255.0)
                : NSColor(r: 0.0, g: 0.0, b: 0.0)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
