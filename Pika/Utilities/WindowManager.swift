import SwiftUI

class WindowManager: ObservableObject {
    @Published var toolbarPadding: CGFloat = 0
    @Published var screenHeight: CGFloat = NSScreen.main!.frame.height - 100
}
