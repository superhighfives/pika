//
//  VersionView.swift
//  Pika
//
//  Created by Charlie Gleason on 30/12/2020.
//

import SwiftUI

struct VersionView: View {
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    var body: some View {
      
      VStack(spacing: 10.0) {
        VStack(spacing: 2.0) {
          Image("StatusBarIcon")
          Text("Pika")
            .font(.title)
        }
        HStack(alignment: .bottom) {
          Text("Version \(appVersion ?? "Unknown")")
            .bold()
          Text("(Build \(buildNumber ?? "Unknown"))")
            .foregroundColor(.gray)
        }
      }
    }
}

struct VersionView_Previews: PreviewProvider {
    static var previews: some View {
        VersionView()
    }
}
