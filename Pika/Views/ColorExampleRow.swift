//
//  ColorExampleRow.swift
//  Pika
//
//  Created by Charlie Gleason on 09/05/2022.
//

import SwiftUI

struct ColorExampleRow: View {
    var copyFormat: CopyFormat
    @ObservedObject var eyedropper: Eyedropper

    var body: some View {
        HStack(alignment: .bottom, spacing: 6.0) {
            ForEach(ColorFormat.allCases, id: \.self) { value in
                HStack(alignment: .bottom, spacing: 2.0) {
                    Text(value.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .opacity(0.65)

                    Text(value.getExample(color: eyedropper.color, style: copyFormat))
                        .font(.system(size: 10))
                }
            }
        }
//      TODO: Fix this on light mode
        .foregroundColor(.gray)
    }
}

struct ColorExampleRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorExampleRow(copyFormat: CopyFormat.css, eyedropper: Eyedroppers().foreground)
    }
}
