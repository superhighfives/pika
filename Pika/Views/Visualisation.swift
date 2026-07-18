import MetalKit
import SwiftUI

/// Reports the hosting `NSWindow` up to SwiftUI so notification handlers can tell this
/// window's events apart from those of transient popups (e.g. a Picker's menu window).
private struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { window = view.window }
        return view
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        DispatchQueue.main.async {
            if window == nil { window = nsView.window }
        }
    }
}

struct Visualisation: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var device: MTLDevice!
    @State var isShown = false
    @State var renderID = UUID()
    @State private var hostWindow: NSWindow?

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }

        self.device = device
    }

    var body: some View {
        ZStack {
            if isShown {
                if device != nil {
                    MetalShader()
                        .id(renderID)
                        .transition(.opacity)
                } else {
                    GeometryReader { geo in
                        Image("AppBackground")
                            .resizable()
                            .frame(maxWidth: geo.size.width,
                                   maxHeight: geo.size.height,
                                   alignment: .center)
                            .clipped()
                    }
                }
            }
        }
        .background(WindowAccessor(window: $hostWindow))
        .animation(.easeIn(duration: 0.8), value: isShown)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isShown = true
            }
        }
        // Only react to this view's own window. Otherwise a transient popup — like the
        // menu window a Picker opens — fires willClose/didBecomeKey and wrongly toggles
        // the shader (which made the header animation vanish when changing a dropdown).
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            guard isHostWindow(note) else { return }
            if !isShown {
                renderID = UUID()
                isShown = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification)) { note in
            guard isHostWindow(note) else { return }
            isShown = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            guard isHostWindow(note) else { return }
            isShown = false
        }
    }

    private func isHostWindow(_ note: Notification) -> Bool {
        guard let hostWindow else { return false }
        return (note.object as? NSWindow) === hostWindow
    }
}

struct VisualisationHeader<Content: View>: View {
    let height: CGFloat
    let alignment: Alignment
    let content: Content

    init(
        height: CGFloat = 150,
        alignment: Alignment = .bottomLeading,
        @ViewBuilder content: () -> Content
    ) {
        self.height = height
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: alignment) {
            ZStack {
                Color(red: 0.4, green: 0.0, blue: 0.7)
                Visualisation()
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white, location: 0.55),
                                .init(color: .white, location: 1),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(height: height)
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(maxWidth: .infinity)
                .frame(height: height)
            content
        }
    }
}

struct VisualisationView_Previews: PreviewProvider {
    static var previews: some View {
        Visualisation()
            .frame(width: 400, height: 400)
    }
}
