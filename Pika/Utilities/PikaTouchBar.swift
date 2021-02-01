import Cocoa
import Combine
import Defaults

extension NSTouchBarItem.Identifier {
    static let foreground = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.foreground")
    static let background = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.background")
    static let ratio = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.ratio")
    static let wcag = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.wcag")
}

extension NSApplication: NSTouchBarDelegate {
    override open func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.foreground, .background, .ratio, .wcag]
        return touchBar
    }

    public func touchBar(
        _: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        let foreground = delegate!.eyedroppers.foreground
        let background = delegate!.eyedroppers.background

        switch identifier {
        case NSTouchBarItem.Identifier.foreground:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "", target: nil, action: #selector(AppDelegate.terminatePika))
            foreground.$color.sink {
                button.title = $0.toFormat(format: Defaults[.colorFormat])
                button.contentTintColor = foreground.getUIColor()
                button.bezelColor = $0
            }
            .store(in: &delegate!.cancellables)
            item.view = button
            return item

        case NSTouchBarItem.Identifier.background:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "", target: nil, action: #selector(AppDelegate.terminatePika))
            background.$color.sink {
                button.title = $0.toFormat(format: Defaults[.colorFormat])
                button.contentTintColor = background.getUIColor()
                button.bezelColor = $0
            }
            .store(in: &delegate!.cancellables)
            item.view = button
            return item

        case NSTouchBarItem.Identifier.ratio:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let textField = NSTextField(labelWithString: "Contrast Ratio")
            item.view = textField
            foreground.$color.sink { textField.stringValue = $0.toContrastRatioString(with: background.color) }
                .store(in: &delegate!.cancellables)
            background.$color.sink { textField.stringValue = $0.toContrastRatioString(with: foreground.color) }
                .store(in: &delegate!.cancellables)
            return item

        case NSTouchBarItem.Identifier.wcag:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSTextField(labelWithString: "WCAG")
            return item
        default:
            return nil
        }
    }
}
