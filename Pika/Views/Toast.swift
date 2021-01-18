//
//  ToastView.swift
//  Pika
//
//  Created by Charlie Gleason on 18/01/2021.
//

import SwiftUI

extension View {
    func toast(isShowing: Binding<Bool>, text: Text) -> some View {
        Toast(isShowing: isShowing,
              presenting: { self },
              text: text)
    }
}

struct Toast<Presenting>: View where Presenting: View {
    /// The binding that decides the appropriate drawing in the body.
    @Binding var isShowing: Bool
    /// The view that will be "presenting" this toast
    let presenting: () -> Presenting
    /// The text to show
    let text: Text

    var body: some View {
        if self.isShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    self.isShowing = false
                }
            }
        }
        return GeometryReader { geometry in

            ZStack(alignment: .center) {
                self.presenting()
                HStack {
                    IconImage(name: "doc.on.doc")
                    self.text
                }
                .frame(width: geometry.size.width - 20,
                       height: 35)
                .background(Color.black.opacity(0.4))
                .foregroundColor(Color.white.opacity(0.75))
                .cornerRadius(4)
                .transition(.slide)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}
