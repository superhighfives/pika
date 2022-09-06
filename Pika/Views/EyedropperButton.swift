import Combine
import Defaults
import SwiftUI

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat
    @Default(.hideColorNames) var hideColorNames

    @State var copyVisible: Bool = false
    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)

    var body: some View {
        ZStack {
            Button(action: {
                NSApp.sendAction(eyedropper.type.pickSelector, to: nil, from: nil)
            }, label: {
                ZStack {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(eyedropper.type.description)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(eyedropper.color.getUIColor().opacity(0.75))

                        VStack(alignment: .leading, spacing: 6.0) {
                            Text(eyedropper.color.toFormat(format: colorFormat, style: copyFormat))
                                .foregroundColor(eyedropper.color.getUIColor())
                                .font(.system(size: 18, weight: .regular))

                            if !hideColorNames {
                                Text(eyedropper.getClosestColor())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(eyedropper.color.getUIColor())
                            }
                        }
                    }
                    .padding(.all, 10.0)
                    .modify {
                        let shadowColor: Color = eyedropper.color.getUIColor() == .white ? .black : .white
                        $0
                            .shadow(color: shadowColor.opacity(0.30), radius: 0, x: 0, y: 1)
                            .shadow(color: shadowColor.opacity(0.10), radius: 3, x: 0, y: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            })
                .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))

            Button(action: {
                NSApp.sendAction(eyedropper.type.copySelector, to: nil, from: nil)
            }, label: {
                IconImage(name: "doc.on.doc", resizable: true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            })
                .buttonStyle(SwapButtonStyle(
                    isVisible: copyVisible,
                    alt: PikaText.textColorCopy
                ))
                .padding(.all, 8.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onHover { hover in
            if hover {
                copyVisible = true
                timerSubscription?.cancel()
                timerSubscription = nil
            } else {
                if self.timerSubscription == nil {
                    self.timer = Timer.publish(every: 0.25, on: .main, in: .common)
                    self.timerSubscription = self.timer.connect()
                }
            }
        }
        .onReceive(timer) { _ in
            copyVisible = false
            timerSubscription?.cancel()
            timerSubscription = nil
        }
    }
}

struct EyedropperButton_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperButton(
            eyedropper: Eyedropper(type: .foreground, color: NSColor.black)
        )
    }
}
