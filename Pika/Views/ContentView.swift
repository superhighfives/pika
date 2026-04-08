import Combine
import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Default(.showColorPreview) var showColorPreview
    @Default(.showCompliance) var showCompliance
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    @State var swapVisible: Bool = false
    @State private var swapTimerSubscription: Cancellable?
    @State private var swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Divider()
            ColorPickers()
                .onHover { hover in
                    guard hover else { return }
                    swapVisible = true
                    swapTimerSubscription?.cancel()
                    swapTimerSubscription = nil
                }
                .onReceive(swapTimer) { _ in
                    swapVisible = false
                    swapTimerSubscription?.cancel()
                    swapTimerSubscription = nil
                }
                .overlay(
                    SwapPreviewButton(
                        foreground: eyedroppers.foreground,
                        background: eyedroppers.background,
                        showPreview: showColorPreview,
                        isVisible: swapVisible,
                        onSwap: {
                            NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
                        }
                    )
                    .onReceive(NotificationCenter.default.publisher(for: .triggerSwap)) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            eyedroppers.swap()
                        }
                    }
                    .focusable(false)
                    .padding(16.0)
                    .frame(maxHeight: .infinity, alignment: .top)
                )
                .onHover { hover in
                    guard !hover, swapTimerSubscription == nil else {
                        return
                    }
                    swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)
                    swapTimerSubscription = swapTimer.connect()
                }

            Divider()
            if showCompliance {
                Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if historyDrawerVisible {
                ColorHistoryDrawer(foreground: eyedroppers.foreground, background: eyedroppers.background)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if Defaults[.palettes].first?.pairs.isEmpty ?? true {
                eyedroppers.recordHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorPicked)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                eyedroppers.recordHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleHistory)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                historyDrawerVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleColorPreview)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showColorPreview.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleCompliance)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                showCompliance.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyPrevious)) { _ in
            guard historyDrawerVisible else { return }
            eyedroppers.navigatePrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyNext)) { _ in
            guard historyDrawerVisible else { return }
            eyedroppers.navigateNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyDelete)) { _ in
            guard historyDrawerVisible else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                eyedroppers.deleteCurrentEntry()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyText)) { _ in
            pasteboard.clearContents()
            let contents = Exporter.toText(
                foreground: eyedroppers.foreground, background: eyedroppers.background,
                style: copyFormat
            )
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyData)) { _ in
            pasteboard.clearContents()
            let contents = Exporter.toJSON(
                foreground: eyedroppers.foreground, background: eyedroppers.background,
                style: copyFormat
            )
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPalette)) { notification in
            let idx: Int
            if let paletteIndex = notification.object as? Int {
                idx = paletteIndex
            } else if !historyDrawerVisible {
                idx = 0
            } else {
                idx = activePaletteIndex
            }
            let palette: Palette? = (idx >= 0 && idx < palettes.count) ? palettes[idx] : palettes.first
            guard let palette = palette else { return }

            let json = Exporter.paletteToJSON(pairs: palette.pairs, name: palette.name)
            let fileName = (palette.name ?? "color-history")
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(fileName).json"
            savePanel.isExtensionHidden = false
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try? json.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Eyedroppers())
    }
}
