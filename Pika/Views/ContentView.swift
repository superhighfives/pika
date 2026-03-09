import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    @State var swapVisible: Bool = false
    @State private var swapHideTask: Task<Void, Never>?
    @State private var angle: Double = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .onHover { hover in
                    if hover {
                        swapHideTask?.cancel()
                        swapHideTask = nil
                        swapVisible = true
                    } else {
                        swapHideTask = Task {
                            try? await Task.sleep(for: .milliseconds(250))
                            swapVisible = false
                        }
                    }
                }
                .overlay(
                    Button(action: {
                        NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
                        angle -= 180
                    }, label: {
                        IconImage(name: "arrow.triangle.swap")
                            .rotationEffect(.degrees(angle))
                            .animation(.easeInOut, value: angle)
                    })
                    .buttonStyle(SwapButtonStyle(
                        isVisible: swapVisible,
                        alt: PikaText.textColorSwap,
                        ltr: true
                    ))
                    .onReceive(NotificationCenter.default.publisher(for: .triggerSwap)) { _ in
                        swap(&eyedroppers.foreground.color, &eyedroppers.background.color)
                    }
                    .focusable(false)
                    .padding(16.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                )

            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
        }
        .onAppear {
            eyedroppers.background.color = colorScheme == .light
                ? NSColor.white
                : NSColor.black
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyText)) { _ in
            pasteboard.clearContents()
            let contents = "\(Exporter.toText(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyData)) { _ in
            pasteboard.clearContents()
            let contents = "\(Exporter.toJSON(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
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
