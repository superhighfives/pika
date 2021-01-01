//
//  AboutView.swift
//  Pika
//
//  Created by Charlie Gleason on 24/12/2020.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16.0) {
            VersionView()
            VStack(spacing: 20.0) {
                HStack(spacing: 20.0) {
                    Link("Website",
                         destination: URL(string: "https://superhighfives/pika")!)
                    Link("GitHub",
                         destination: URL(string: "https://github.com/superhighfives/pika")!)
                }

                Divider()

                HStack(spacing: 5.0) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Designed by")
                    Link("Charlie Gleason",
                         destination: URL(string: "https://charliegleason.com")!)
                }.font(.callout)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
