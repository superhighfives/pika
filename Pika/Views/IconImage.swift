//
//  File.swift
//  Pika
//
//  Created by Charlie Gleason on 06/01/2021.
//

import SwiftUI

struct IconImage: View {
    var name: String

    var body: some View {
        if #available(OSX 11.0, *) {
            return Image(systemName: name)
        } else {
            return Image(name)
        }
    }
}
