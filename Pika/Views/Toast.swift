import SwiftUI

extension View {
    func toast(isShowing: Binding<Bool>, text: Text) -> some View {
        Toast(isShowing: isShowing,
              presenting: { self },
              text: text)
    }
}

struct Toast<Presenting>: View where Presenting: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var isShowing: Bool
    let presenting: () -> Presenting
    let text: Text

    var body: some View {
        if self.isShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
                .font(.system(size: 10.0))
                .background(Color.black.opacity(0.6))
                .foregroundColor(Color.white.opacity(0.8))
                .cornerRadius(12)
                .transition(.slide)
                .opacity(self.isShowing ? 1 : 0)
                .offset(x: 4.0, y: 4.0)
            }
        }
    }
}
