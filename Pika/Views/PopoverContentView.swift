import SwiftUI

struct PopoverContentView: View {
    let eyedroppers: Eyedroppers

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                NavigationMenu()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
            ContentView()
                .frame(minHeight: 280, idealHeight: 280, alignment: .center)
        }
        .environmentObject(eyedroppers)
        .frame(width: 480)
    }
}
