import Combine
import Defaults
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Default(.paletteText) var paletteText
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    /// When provided (popover path), avoids re-parsing paletteText that PopoverContentView already parsed.
    var externalPalettes: [ColorPalette]?

    @State var swapVisible: Bool = false
    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var angle: Double = 0

    private var palettes: [ColorPalette] {
        externalPalettes ?? PaletteParser.parse(paletteText)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .onHover { hover in
                    guard hover else { return }
                    swapVisible = true
                    timerSubscription?.cancel()
                    timerSubscription = nil
                }
                .onReceive(timer) { _ in
                    swapVisible = false
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
                            .animation(.easeInOut, value: angle)
                    })
                    .buttonStyle(SwapButtonStyle(
                        isVisible: swapVisible,
                        alt: PikaText.textColorSwap,
                        ltr: true
                    ))
                    .focusable(false)
                    .padding(16.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                )
                .onHover { hover in
                    guard !hover, timerSubscription == nil else {
                        return
                    }
                    timer = Timer.publish(every: 0.25, on: .main, in: .common)
                    timerSubscription = timer.connect()
                }

            Divider()
            Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
            ColorHistory()
            ColorPalettes(palettes: palettes)
        }
        .onAppear {
            if !eyedroppers.hasSetInitialBackground {
                eyedroppers.hasSetInitialBackground = true
                eyedroppers.background.color = colorScheme == .light
                    ? NSColor.white
                    : NSColor.black
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyText)))
        { _ in
            pasteboard.clearContents()
            // swiftlint:disable line_length
            let contents = "\(Exporter.toText(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
            // swiftlint:enable line_length
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name(PikaConstants.ncTriggerCopyData)))
        { _ in
            pasteboard.clearContents()
            // swiftlint:disable line_length
            let contents = "\(Exporter.toJSON(foreground: eyedroppers.foreground, background: eyedroppers.background, style: copyFormat))"
            // swiftlint:enable line_length
            pasteboard.setString(contents, forType: .string)
        }
    }
}

/// Shared layout constants for dynamic height calculation.
/// Used by both PopoverContentView and AppDelegate.updateWindowSize().
enum SwatchLayout {
    /// Height of a single swatch section (Divider + SwatchBar + padding).
    static let swatchSectionHeight: CGFloat = 52
    static let maxHeight: CGFloat = 550

    static func totalHeight(base: CGFloat, hasHistory: Bool, paletteCount: Int) -> CGFloat {
        var height = base
        if hasHistory {
            height += swatchSectionHeight
        }
        height += CGFloat(paletteCount) * swatchSectionHeight
        return min(height, maxHeight)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Eyedroppers())
    }
}
