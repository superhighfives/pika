//
//  File.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import Defaults

enum ColorFormatKeys: String, Codable, CaseIterable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsb = "HSB"
}

extension Defaults.Keys {
    static let colorFormat = Key<ColorFormatKeys>("colorFormat", default: .hex)
    static let viewedSplash = Key<Bool>("viewedSplash", default: false)
}
