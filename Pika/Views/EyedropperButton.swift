import Defaults
import SwiftUI

struct EyedropperButton: View {
    @ObservedObject var eyedropper: Eyedropper
    @Default(.colorFormat) var colorFormat

    func getUIColor() -> (Color) {
        return (eyedropper.color.luminance < 0.3 ? Color.white : Color.black)
    }

    var body: some View {
        Button(action: { eyedropper.start() }, label: {
            ZStack {
                Group {
                    Rectangle()
                        .fill(Color(eyedropper.color.overlay(with: NSColor.black)))
                        .frame(height: 55.0)
                }
                .opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 0.0) {
                    Text(eyedropper.title)
                        .font(.caption)
                        .bold()
                        .foregroundColor(getUIColor().opacity(0.5))
                    HStack {
                        Text(eyedropper.color.toFormat(format: colorFormat))
                            .foregroundColor(getUIColor())
                            .font(.system(size: 18, weight: .regular))
                        IconImage(name: "eyedropper")
                            .foregroundColor(getUIColor())
                            .padding(.leading, 0.0)
                            .opacity(0.8)
                    }
                }
                .padding([.bottom, .leading], 10.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        })
            .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
            .contextMenu {
                ColorMenuItems(eyedropper: eyedropper)
            }
    }
}

struct EyedropperButton_Previews: PreviewProvider {
    static var previews: some View {
        EyedropperButton(
            eyedropper: Eyedropper(title: "Foreground", color: NSColor.black)
        )
    }
}
