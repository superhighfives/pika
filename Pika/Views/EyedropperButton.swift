import Defaults
import SwiftUI

struct EyedropperButton: View {
    var eyedropper: Eyedropper
    var uiColor: Color

    @Default(.colorFormat) var colorFormat

    var body: some View {
        Button(action: { eyedropper.start() }, label: {
            ZStack {
                Group {
                    Rectangle()
                        .fill(Color(eyedropper.color.darkened(amount: 0.5)))
                        .frame(height: 55.0)
                }
                .opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 0.0) {
                    Text(eyedropper.title)
                        .font(.caption)
                        .bold()
                        .foregroundColor(uiColor.opacity(0.5))
                    HStack {
                        Text(eyedropper.color.toFormat(format: colorFormat))
                            .foregroundColor(uiColor)
                            .font(.system(size: 18, weight: .regular))
                        IconImage(name: "eyedropper")
                            .foregroundColor(uiColor)
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
    private struct ViewWrapper: View {
        var eyedropper = Eyedropper(title: "Foreground", color: NSColor.white)

        var body: some View {
            EyedropperButton(eyedropper: self.eyedropper, uiColor: Color.white)
        }
    }

    static var previews: some View {
        ViewWrapper()
    }
}
