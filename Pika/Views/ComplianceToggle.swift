//
//  ComplianceToggle.swift
//  Pika
//
//  Created by Charlie Gleason on 01/01/2021.
//

import SwiftUI

struct ComplianceToggle: View {
    var title: String
    var isCompliant: Bool
    var tooltip: String

    var body: some View {
        let view = HStack(spacing: 2.0) {
            IconImage(name: isCompliant ? "checkmark.circle.fill" : "xmark.circle")
                .opacity(isCompliant ? 1.0 : 0.4)
            Text(title)
        }
        .opacity(isCompliant ? 1.0 : 0.4)
        if #available(OSX 11.0, *) {
          view.help(tooltip)
        }
    }
}

struct ComplianceToggle_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceToggle(title: "AA", isCompliant: true, tooltip: "Help text")
    }
}
