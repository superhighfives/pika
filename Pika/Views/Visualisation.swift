import MetalKit
import SwiftUI

struct Visualisation: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var device: MTLDevice!
    @State var isShown = false
    @State var renderID = UUID()

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
        .animation(.easeIn(duration: 0.3), value: isShown)
        .onAppear {
            isShown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            if !isShown {
                renderID = UUID()
                isShown = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification)) { _ in
            isShown = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            isShown = false
        }
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
