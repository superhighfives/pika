import MetalKit
import SwiftUI

struct Visualisation: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var device: MTLDevice!
    @State var isShown = false

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
                        .transition(.opacity)
                } else {
                    GeometryReader { geo in
                        Image("AppBackground")
                            .resizable()
                            .frame(maxWidth: geo.size.width,
                                   maxHeight: geo.size.height,
                                   alignment: .center)
                            .clipped()
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(Animation.easeInOut(duration: 1)) // delay is optional, for demo
        .onAppear {
            self.isShown.toggle()
        }
        .background(Color(PikaConstants.initialColors.randomElement()!))
    }
}

struct VisualisationView_Previews: PreviewProvider {
    static var previews: some View {
        Visualisation()
            .frame(width: 400, height: 400)
    }
}
