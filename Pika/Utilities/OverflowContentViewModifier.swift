import SwiftUI

extension View {
    func useScrollView(
        when condition: Bool,
        showsIndicators: Bool = true
    ) -> AnyView {
        if condition {
            return AnyView(
                ScrollView(showsIndicators: showsIndicators) {
                    self
                }
            )
        } else {
            return AnyView(self)
        }
    }
}
