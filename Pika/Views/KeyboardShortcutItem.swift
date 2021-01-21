//
//  KeyboardShortcutItem.swift
//  Pika
//
//  Created by Charlie Gleason on 21/01/2021.
//

import SwiftUI

struct KeyboardShortcutItem: View {
    @State var title: String
    @State var keys: [String]

    var body: some View {
        VStack(spacing: 4.0) {
            Text(title)
            HStack(spacing: 4.0) {
                ForEach(keys, id: \.self) { key in
                    KeyboardShortcutKey { Text(key) }
                }
            }
        }
    }
}

struct KeyboardShortcutItem_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutItem(title: "Copy Example", keys: ["A", "B"])
    }
}
