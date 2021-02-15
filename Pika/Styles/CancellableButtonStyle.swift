import Combine
import SwiftUI

struct CancellableButtonStyle: PrimitiveButtonStyle {
    var isVisible: Bool
    var isHovered: Bool
    var fgColor: Color
    var bgColor: Color

    private struct CancellableButton: View {
        var isVisible: Bool
        var isHovered: Bool
        var fgColor: Color
        var bgColor: Color

        @State private var timerSubscription: Cancellable?
        @State private var timer = Timer.publish(every: 1, on: .main, in: .common)
        @State private var countDown = 0

        let configuration: Configuration
        let timeOut: Int

        var body: some View {
            Button(action: {
                if self.timerSubscription == nil {
                    self.timer = Timer.publish(every: 1, on: .main, in: .common)
                    self.timerSubscription = self.timer.connect()
                    self.countDown = self.timeOut
                } else {
                    self.cancelTimer()
                }
            }, label: {
                if timerSubscription == nil {
                    configuration.label

                } else {
                    Text("Cancel? \(countDown)")
                }
            })
                .buttonStyle(CancellableButtonButtonStyle(
                    isVisible: isVisible,
                    isHovered: isHovered,
                    fgColor: fgColor,
                    bgColor: bgColor
                ))
                .onReceive(timer) { _ in
                    if self.countDown > 1 {
                        self.countDown -= 1
                    } else {
                        self.configuration.trigger()
                        self.cancelTimer()
                    }
                }
        }

        func cancelTimer() {
            timerSubscription?.cancel()
            timerSubscription = nil
        }
    }

    var timeOut = 3 // set this number of second before action will take place

    func makeBody(configuration: Configuration) -> some View {
        CancellableButton(
            isVisible: isVisible,
            isHovered: isHovered,
            fgColor: fgColor,
            bgColor: bgColor,
            configuration: configuration,
            timeOut: timeOut
        )
    }
}

struct CancellableButtonButtonStyle: ButtonStyle {
    var isVisible: Bool
    var isHovered: Bool
    var fgColor: Color
    var bgColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .shadow(
                            color: Color.white.opacity(0.5),
                            radius: configuration.isPressed ? 3 : 8,
                            x: configuration.isPressed ? -4 : -12,
                            y: configuration.isPressed ? -4 : -12
                        )
                        .shadow(
                            color: Color.black.opacity(0.5),
                            radius: configuration.isPressed ? 3 : 8,
                            x: configuration.isPressed ? 4 : 12,
                            y: configuration.isPressed ? 4 : 12
                        )
                        .blendMode(.overlay)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(bgColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.white.opacity(0.2))
                        )
                }
            )
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(isVisible ? 1.0 : 0.0)
            .foregroundColor(fgColor)
            .animation(.spring())
    }
}
