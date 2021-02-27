import Combine
import Defaults
import SwiftUI

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
    @Default(.colorFormat) var colorFormat
    let pasteboard = NSPasteboard.general

    @State var copyVisible: Bool = false
    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 0.25, on: .main, in: .common)

    var body: some View {
        ZStack {
            Button(action: {
                let action = eyedropper.type == .foreground
                    ? #selector(AppDelegate.triggerPickForeground)
                    : #selector(AppDelegate.triggerPickBackground)
                NSApp.sendAction(action, to: nil, from: nil)
            }, label: {
                ZStack {
                    Group {
                        Rectangle()
                            .fill(Color(eyedropper.color.overlay(with: NSColor.black)))
                            .frame(height: 55.0)
                    }
                    .opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                    IconImage(name: "eyedropper")
                        .foregroundColor(eyedropper.color.getUIColor())
                        .padding(.all, 12.0)
                        .opacity(copyVisible ? 0.8 : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .animation(.easeInOut)

                    VStack(alignment: .leading, spacing: 0.0) {
                        Text(eyedropper.type == .foreground
                            ? NSLocalizedString("color.foreground", comment: "Foreground")
                            : NSLocalizedString("color.background", comment: "Background"))
                            .font(.caption)
                            .bold()
                            .foregroundColor(eyedropper.color.getUIColor().opacity(0.5))
                        HStack {
                            Text(eyedropper.color.toFormat(format: colorFormat))
                                .foregroundColor(eyedropper.color.getUIColor())
                                .font(.system(size: 18, weight: .regular))
                        }
                    }
                    .padding(.all, 10.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            })
                .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))

            Button(action: {
                let action = eyedropper.type == .foreground
                    ? #selector(AppDelegate.triggerCopyForeground)
                    : #selector(AppDelegate.triggerCopyBackground)
                NSApp.sendAction(action, to: nil, from: nil)
            }, label: {
                IconImage(name: "doc.on.doc", resizable: true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            })
                .buttonStyle(SwapButtonStyle(
                    isVisible: copyVisible,
                    alt: NSLocalizedString("color.copy", comment: "Copy")
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
