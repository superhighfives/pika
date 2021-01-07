//
//  AboutView.swift
//  Pika
//
//  Created by Charlie Gleason on 24/12/2020.
//

import SwiftUI

struct AboutView: View {
  
  @ViewBuilder
  func getLink(title: String, link: URL) -> some View {
    if #available(OSX 11.0, *) {
      Link(title,
           destination: link)
    } else {
      Button(title) {
        NSWorkspace.shared.open(link)
      }
      .buttonStyle(.LinkButtonStyle)
    }
  }
  
  var body: some View {
    VStack(spacing: 16.0) {
      VersionView()
      VStack(spacing: 20.0) {
        HStack(spacing: 20.0) {
          getLink(title: "Website",
                  link: URL(string: "https://superhighfives/pika")!)
          getLink(title: "GitHub",
                  link: URL(string: "https://github.com/superhighfives/pika")!)
          
        }
        
        Divider()
        
        HStack(spacing: 5.0) {
          Image(systemName: "hand.thumbsup.fill")
          Text("Designed by")
          Button("Charlie Gleason",
                 destination: URL(string: "https://charliegleason.com")!)
            .buttonStyle(.LinkButtonStyle)
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
