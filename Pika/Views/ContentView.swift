import Combine
import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @State var swapVisible: Bool = false

    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var countDown = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .onHover { hover in
                    if hover {
                        swapVisible = true
                        timerSubscription?.cancel()
                        timerSubscription = nil
                    } else {
                        if self.timerSubscription == nil {
                            self.timer = Timer.publish(every: 0.25, on: .main, in: .common)
                            self.timerSubscription = self.timer.connect()
                        }
                    }
                }
                .onReceive(timer) { _ in
                    swapVisible = false
                    timerSubscription?.cancel()
                    timerSubscription = nil
                }
                .overlay(
                    Button(action: {
                        swap(&eyedroppers.foreground.color, &eyedroppers.background.color)
                    }, label: {
                        IconImage(name: "arrow.triangle.swap")
                    })
                        .buttonStyle(SwapButtonStyle(isVisible: swapVisible))
                )
            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
        .onAppear {
            eyedroppers.background.color = colorScheme == .light
                ? NSColor.white
                : NSColor.black
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
