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
            ZStack(alignment: .bottom) {
                Visualisation()
                    .frame(maxHeight: .infinity)
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                    .frame(maxWidth: .infinity, maxHeight: 100.0)
            }
            VersionView()
                .padding(EdgeInsets(top: -50, leading: 0, bottom: 0, trailing: 0))
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
                }
            }
            .padding(.bottom, 20.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
