import Cocoa
import SwiftUI

extension NSTouchBarItem.Identifier {
    static let splash = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.splash")
}

class SplashTouchBarController: NSWindowController, NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.splash]
        return touchBar
    }

    func touchBar(_: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.splash:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSHostingView(rootView: TouchBarVisual())
            return item
        default:
            return nil
        }
    }
}
