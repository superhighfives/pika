import Defaults
import SwiftUI

struct PopoverContentView: View {
    let eyedroppers: Eyedroppers

    @Default(.historyDrawerVisible) var historyDrawerVisible

    /// Content height with the history drawer closed.
    private static let baseHeight: CGFloat = 280
    var body: some View {
        // Grows by the drawer's height, so the swatches keep their size and the content clears
        // `PikaAdaptiveHeight.palettes`, below which `ContentView` hides the drawer.
        let height = Self.baseHeight + (historyDrawerVisible ? ColorHistoryDrawer.height : 0)
        VStack(spacing: 0) {
            HStack {
                Spacer()
                NavigationMenu()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
            ContentView()
                .frame(minHeight: height, idealHeight: height, alignment: .center)
        }
        .environmentObject(eyedroppers)
        .frame(width: 480)
    }
}
