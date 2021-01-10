import MetalKit
import SwiftUI

struct Visualisation: View {
    var device: MTLDevice!

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
        }
    }

    var body: some View {
        if device != nil {
            MetalShader()
        } else {
            GeometryReader { geo in
                Image("AppBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: geo.size.width,
                           maxHeight: geo.size.height,
                           alignment: .center)
                    .clipped()
            }
        }
    }
}

struct VisualisationView_Previews: PreviewProvider {
    static var previews: some View {
        Visualisation()
    }
}
