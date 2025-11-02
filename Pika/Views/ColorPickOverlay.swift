import SwiftUI

class ColorPickOverlayViewModel: ObservableObject {
    @Published var opacity: Double = 0

    static let fadeInDuration: TimeInterval = 0.2
    static let fadeOutDuration: TimeInterval = 0.2

    func fadeIn() {
        withAnimation(.easeOut(duration: ColorPickOverlayViewModel.fadeInDuration)) {
            opacity = 1
        }
    }

    func fadeOut(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: ColorPickOverlayViewModel.fadeOutDuration)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ColorPickOverlayViewModel.fadeOutDuration) {
            completion()
        }
    }
}

struct ColorPickOverlay: View {
    let colorText: String
    let pickedColor: NSColor
    @ObservedObject var viewModel: ColorPickOverlayViewModel

    private var contrastColor: Color {
        pickedColor.getUIColor()
    }

    var body: some View {
        Text(colorText)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(contrastColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(pickedColor),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(pickedColor.getUIColor().opacity(0.2), lineWidth: 1)
            )
            .fixedSize(horizontal: true, vertical: true)
            .opacity(viewModel.opacity)
            .onAppear {
                viewModel.fadeIn()
            }
    }
}

struct ColorPickCrosshair: View {
    let pickedColor: NSColor
    @ObservedObject var viewModel: ColorPickOverlayViewModel

    private var contrastColor: Color {
        pickedColor.getUIColor()
    }

    var body: some View {
        ZStack {
            // Outer glow for visibility
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
                .frame(width: 20, height: 20)
                .blur(radius: 2)

            // Black outer ring
            Circle()
                .strokeBorder(.black.opacity(0.2), lineWidth: 1.5)
                .frame(width: 18, height: 18)

            // White middle ring for contrast
            Circle()
                .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                .frame(width: 16, height: 16)

            // Inner color circle
            Circle()
                .fill(Color(pickedColor))
                .frame(width: 10, height: 10)

            // Inner ring around color
            Circle()
                .strokeBorder(contrastColor.opacity(0.5), lineWidth: 0.5)
                .frame(width: 10, height: 10)

            // Crosshair lines with gradient effect
            ZStack {
                // Shadow lines for depth
                Path { path in
                    // Horizontal
                    path.move(to: CGPoint(x: 1, y: 9))
                    path.addLine(to: CGPoint(x: 6, y: 9))
                    path.move(to: CGPoint(x: 12, y: 9))
                    path.addLine(to: CGPoint(x: 17, y: 9))
                    // Vertical
                    path.move(to: CGPoint(x: 9, y: 1))
                    path.addLine(to: CGPoint(x: 9, y: 6))
                    path.move(to: CGPoint(x: 9, y: 12))
                    path.addLine(to: CGPoint(x: 9, y: 17))
                }
                .stroke(.black.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                // Main crosshair lines
                Path { path in
                    // Horizontal
                    path.move(to: CGPoint(x: 1, y: 9))
                    path.addLine(to: CGPoint(x: 6, y: 9))
                    path.move(to: CGPoint(x: 12, y: 9))
                    path.addLine(to: CGPoint(x: 17, y: 9))
                    // Vertical
                    path.move(to: CGPoint(x: 9, y: 1))
                    path.addLine(to: CGPoint(x: 9, y: 6))
                    path.move(to: CGPoint(x: 9, y: 12))
                    path.addLine(to: CGPoint(x: 9, y: 17))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            .frame(width: 18, height: 18)
        }
        .frame(width: 20, height: 20)
        .opacity(viewModel.opacity)
    }
}

struct ColorPickOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ColorPickOverlay(colorText: "#232323", pickedColor: NSColor(hex: "#232323"), viewModel: ColorPickOverlayViewModel())
            ColorPickOverlay(colorText: "rgb(35, 35, 35)", pickedColor: NSColor(hex: "#232323"), viewModel: ColorPickOverlayViewModel())
            ColorPickOverlay(colorText: "hsl(0, 0%, 14%)", pickedColor: NSColor(hex: "#232323"), viewModel: ColorPickOverlayViewModel())
            ColorPickOverlay(colorText: "0.14 0.14 0.14", pickedColor: NSColor(hex: "#232323"), viewModel: ColorPickOverlayViewModel())
        }
        .frame(width: 400, height: 400)
    }
}
