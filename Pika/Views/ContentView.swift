import Combine
import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    @State var swapVisible: Bool = false
    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var angle: Double = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .overlay(
                    Button(action: {
                        NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
                        angle -= 180
                    }, label: {
                        IconImage(name: "arrow.triangle.swap")
                            .rotationEffect(.degrees(angle))
                            .animation(.easeInOut)
                    })
                        .buttonStyle(SwapButtonStyle(
                            isVisible: swapVisible,
                            alt: PikaText.textColorSwap
                        ))
                        .onReceive(NotificationCenter.default.publisher(
                            for: Notification.Name(PikaConstants.ncTriggerSwap))) { _ in
                            swap(&eyedroppers.foreground.color, &eyedroppers.background.color)
                        }
                        .focusable(false)
                        .padding(16.0)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
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
            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
        .onAppear {
            eyedroppers.background.color = colorScheme == .light
                ? NSColor.white
                : NSColor.black
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyText))) { _ in
            pasteboard.clearContents()
            // swiftlint:disable line_length
            let contents = "\(Exporter.toText(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
            // swiftlint:enable line_length
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyData))) { _ in
            pasteboard.clearContents()
            // swiftlint:disable line_length
            let contents = "\(Exporter.toJSON(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
            // swiftlint:enable line_length
            pasteboard.setString(contents, forType: .string)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Eyedroppers())
    }
}
