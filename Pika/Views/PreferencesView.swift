//
//  PreferencesView.swift
//  Pika
//
//  Created by Charlie Gleason on 24/12/2020.
//

import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {
  var body: some View {
    
    
    HStack {
      VersionView()
      .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 30.0)
      .frame(width: 180.0)
      
      Divider()
      
      VStack(spacing: 10.0) {
        Text("Preferences")
          .font(.title3)
        
          HStack {
            Text("Global Pika:")
            KeyboardShortcuts.Recorder(for: .togglePika)
          }
      }
      .padding(.all, 20.0)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}
