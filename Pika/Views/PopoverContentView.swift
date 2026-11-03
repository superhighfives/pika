import Defaults
import SwiftUI

struct PopoverContentView: View {
    let eyedroppers: Eyedroppers

    @Default(.historyDrawerVisible) var historyDrawerVisible

    /// Content height with the history drawer closed.
    private static let baseHeight: CGFloat = 280
    /// The drawer's tab bar, chip row and dividers. The popover grows by this when history is
    /// shown, keeping the swatches the same size and clearing `PikaAdaptiveHeight.palettes`,
    /// below which `ContentView` hides the drawer.
    private static let historyDrawerHeight: CGFloat = 74

    var body: some View {
        let height = Self.baseHeight + (historyDrawerVisible ? Self.historyDrawerHeight : 0)
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
