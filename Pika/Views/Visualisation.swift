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

struct VisualisationView_Previews: PreviewProvider {
    static var previews: some View {
        Visualisation()
            .frame(width: 400, height: 400)
    }
}
