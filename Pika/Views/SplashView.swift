//
//  SplashView.swift
//  Pika
//
//  Created by Charlie Gleason on 06/01/2021.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                MetalView()
                Image("AppSplash")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150.0)
            }
            Divider()
            HStack {
                Button(action: {
                    NSApp.sendAction(#selector(AppDelegate.closeSplashWindow), to: nil, from: nil)
                }, label: { Text("Get Started") })
            }
            .frame(maxWidth: .infinity, minHeight: 50.0)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
