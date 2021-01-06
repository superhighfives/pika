import MetalKit
import simd
import SwiftUI

struct MetalView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        context.coordinator.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size

        return mtkView
    }

    func updateNSView(_: MTKView, context _: NSViewRepresentableContext<MetalView>) {}

    class Coordinator: NSObject, MTKViewDelegate {
        let timeStep = Float(1.0 / 60.0)
        var time = Float(0)

        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLComputePipelineState!
        var inputBuffer: MTLBuffer!

        init(_ parent: MetalView) {
            self.parent = parent

            if let device = MTLCreateSystemDefaultDevice() {
                self.device = device
            }
            commandQueue = device.makeCommandQueue()!
            super.init()

            pipelineState = createPipeline()
        }

        func createPipeline() -> MTLComputePipelineState? {
            let library = device.makeDefaultLibrary()!

            do {
                if let kernel = library.makeFunction(name: "compute") {
                    inputBuffer = device.makeBuffer(length: MemoryLayout<simd_float2>.size, options: [])
                    return try device.makeComputePipelineState(function: kernel)
                } else {
                    print("Failed")
                }
            } catch {
                print("\(error)")
            }

            return nil
        }

        func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

        func draw(in view: MTKView) {
            if let drawable = view.currentDrawable {
                time += timeStep
                let inputBufferPtr = inputBuffer.contents().bindMemory(to: simd_float2.self, capacity: 1)
                inputBufferPtr.pointee = simd_float2(time, 0.0)
                guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
                guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
                commandEncoder.setComputePipelineState(pipelineState)
                commandEncoder.setTexture(drawable.texture, index: 0)
                commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
                let width = pipelineState.threadExecutionWidth
                let height = pipelineState.maxTotalThreadsPerThreadgroup / width
                let threadGroupCount = MTLSize(width: width, height: height, depth: 1)
                let threadGroups = MTLSize(width: (drawable.texture.width + width - 1) / width,
                                           height: (drawable.texture.height + height - 1) / height,
                                           depth: 1)
                commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
        }
    }
}
