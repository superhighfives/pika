//
//  KeyboardKey.swift
//  Pika
//
//  Created by Charlie Gleason on 20/01/2021.
//

import SwiftUI

struct KeyboardShortcutKey<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .padding(.vertical, 3.0)
            .padding(.horizontal, 7.0)
            .background(Color(.gray).opacity(0.25))
            .cornerRadius(4)
    }
}

struct KeyboardShortcutKey_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutKey {
            Text("L")
        }
    }
}
