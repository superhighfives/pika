import Combine
import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @StateObject var activeUI = ActiveUI()

    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var angle: Double = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .onHover { hover in
                    if hover {
                        activeUI.visible = true
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
                    activeUI.visible = false
                    timerSubscription?.cancel()
                    timerSubscription = nil
                }
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
                            isVisible: activeUI.visible,
                            alt: NSLocalizedString("color.swap", comment: "Swap")
                        ))
                        .onReceive(NotificationCenter.default.publisher(
                            for: Notification.Name(PikaConstants.ncTriggerSwap))) { _ in
                            swap(&eyedroppers.foreground.color, &eyedroppers.background.color)
                        }
                )
            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
        .environmentObject(activeUI)
        .onAppear {
            eyedroppers.background.color = colorScheme == .light
                ? NSColor.white
                : NSColor.black
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyText))) { _ in
            pasteboard.clearContents()
            let contents = "\(Exporter.toText(eyedroppers.foreground, eyedroppers.background))"
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyData))) { _ in
            pasteboard.clearContents()
            let contents = "\(Exporter.toJSON(eyedroppers.foreground, eyedroppers.background))"
            pasteboard.setString(contents, forType: .string)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
