//
//  ColorNavigation.swift
//  Pika
//
//  Created by Charlie Gleason on 01/01/2021.
//

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

struct ColorNavigation_Previews: PreviewProvider {
    static var previews: some View {
        let eyedropper = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
        ColorNavigation(eyedropper: eyedropper)
    }
}
