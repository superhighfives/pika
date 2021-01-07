//
//  AboutView.swift
//  Pika
//
//  Created by Charlie Gleason on 24/12/2020.
//

import SwiftUI

struct LinkButton: View {
    var title: String
    var link: String

    var body: some View {
        Button(title) {
            NSWorkspace.shared.open(URL(string: link)!)
        }
        .buttonStyle(LinkButtonStyle())
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16.0) {
            VersionView()
            VStack(spacing: 20.0) {
                HStack(spacing: 20.0) {
                    LinkButton(title: "Website", link: "https://superhighfives.com/pika")
                    LinkButton(title: "GitHub", link: "https://github.com/superhighfives/pika")
                }

                Divider()

                HStack(spacing: 5.0) {
                    IconImage(name: "hand.thumbsup.fill")
                    Text("Designed by")
                    LinkButton(title: "Charlie Gleason", link: "https://charliegleason.com")
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
