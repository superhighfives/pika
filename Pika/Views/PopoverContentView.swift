import Defaults
import SwiftUI

struct PopoverContentView: View {
    let appDelegate: AppDelegate

    var body: some View {
        Group {
            if let eyedroppers = appDelegate.eyedroppers {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        NavigationMenu()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    ContentView()
                        .environmentObject(eyedroppers)
                        .frame(minHeight: 280, idealHeight: 280, alignment: .center)
                }
                .environmentObject(eyedroppers)
            } else {
                ProgressView()
                    .frame(height: 280)
            }
        }
        .frame(width: 480)
    }
}
