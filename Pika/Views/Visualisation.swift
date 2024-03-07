import MetalKit
import SwiftUI

struct Visualisation: View {
    var device: MTLDevice!

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }

        self.device = device
    }

    var body: some View {
        if device != nil {
            MetalShader()
        } else {
            GeometryReader { geo in
                Image("AppBackground")
                    .resizable()
                    
                    .frame(maxWidth: geo.size.width,
                           maxHeight: geo.size.height,
                           alignment: .center)
                    .scaledToFill()
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
