import Cocoa
import SwiftUI

extension NSTouchBarItem.Identifier {
    static let splash = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.splash")
}

extension NSApplication: NSTouchBarDelegate {
    override open func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.splash]
        return touchBar
    }

    public func touchBar(_: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.splash:
            let item = NSCustomTouchBarItem(identifier: identifier)
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                item.view = NSHostingView(rootView: TouchBarVisual())
            }
            return item
        default:
            return nil
        }
    }
}
