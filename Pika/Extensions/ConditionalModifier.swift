//
//  ConditionalModifier.swift
//  Pika
//
//  Created by Charlie Gleason on 06/01/2021.
//

import SwiftUI

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
}
