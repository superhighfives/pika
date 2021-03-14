import SwiftUI

extension View {
    func toast(isShowing: Binding<Bool>, color: Color, text: Text) -> some View {
        Toast(isShowing: isShowing,
              presenting: { self },
              text: text,
              color: color)
    }
}

struct Toast<Presenting>: View where Presenting: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var isShowing: Bool
    let presenting: () -> Presenting
    let text: Text
    let color: Color

    var body: some View {
        if self.isShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    self.isShowing = false
                }
            }
        }
        return GeometryReader { _ in

            ZStack(alignment: .topLeading) {
                self.presenting()

                HStack {
                    IconImage(name: "doc.on.doc")
                    self.text
                }
                .padding(.vertical, 5.0)
                .padding(.horizontal, 10.0)
                .font(.system(size: 11.0))
                .foregroundColor(color)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
                .transition(.slide)
                .opacity(self.isShowing ? 1 : 0)
                .offset(x: 8.0, y: 8.0)
            }
        }
    }
}
