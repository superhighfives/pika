//
//  EyedropperButtonStyle.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import SwiftUI

class Eyedropper: ObservableObject {
    var title: String
    @Published public var color: NSColor

    init(title: String, color: NSColor) {
        self.title = title
        self.color = color
    }

    func start() {
        let sampler = NSColorSampler()
        sampler.show { selectedColor in
            if let selectedColor = selectedColor {
                self.color = selectedColor
            }
        }
    }

    func set(color: NSColor) {
        self.color = color
    }
}
