//
//  KeyboardKey.swift
//  Pika
//
//  Created by Charlie Gleason on 20/01/2021.
//

import SwiftUI

struct KeyboardKey<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .padding(.vertical, 4.0)
            .padding(.horizontal, 8.0)
            .background(Color(.gray).opacity(0.25))
            .cornerRadius(4)
    }
}

struct KeyboardKey_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardKey {
            Text("L")
        }
    }
}
