import Cocoa
import Combine
import Defaults
import SwiftUI

extension NSTouchBarItem.Identifier {
    static let icon = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.icon")
    static let eyedroppers = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.eyedroppers")
    static let ratio = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.ratio")
    static let wcag = NSTouchBarItem.Identifier(rawValue: "com.superhighfives.pika.wcag")
}

extension NSApplication: NSTouchBarDelegate {
    override open func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.icon, .eyedroppers, .ratio, .wcag]
        return touchBar
    }

    fileprivate func updateButton(button: NSButton, eyedropper: Eyedropper) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            button.title = eyedropper.color.toFormat(format: Defaults[.colorFormat])
            button.contentTintColor = eyedropper.getUIColor()
            button.bezelColor = eyedropper.color
        }
    }

    func createTouchBarButton(
        _ eyedropper: Eyedropper,
        _ delegate: AppDelegate?
    ) -> NSButton? {
        let action = eyedropper.title == "Foreground"
            ? #selector(AppDelegate.triggerPickForeground)
            : #selector(AppDelegate.triggerPickBackground)
        let button = NSButton(title: "", target: nil, action: action)
        button.image = NSImage(named: "eyedropper")
        button.imagePosition = .imageLeft
        button.setButtonType(NSButton.ButtonType.toggle)
        eyedropper.$color.sink { _ in
            self.updateButton(button: button, eyedropper: eyedropper)
        }
        .store(in: &delegate!.cancellables)
        Defaults.observe(.colorFormat) { _ in
            self.updateButton(button: button, eyedropper: eyedropper)
        }.tieToLifetime(of: self)
        return button
    }

    func getWCAGViews(
        wcag: NSColor.WCAG
    ) -> [NSView] {
        [
            NSHostingView(rootView:
                ComplianceToggle(
                    title: "AA",
                    isCompliant: wcag.level2A,
                    tooltip: PikaConstants.AAText
                )),
            NSHostingView(rootView:
                ComplianceToggle(
                    title: "AA+",
                    isCompliant: wcag.level2ALarge,
                    tooltip: PikaConstants.AAPlusText
                )),
            NSHostingView(rootView:
                ComplianceToggle(
                    title: "AAA",
                    isCompliant: wcag.level3A,
                    tooltip: PikaConstants.AAAText
                )),
            NSHostingView(rootView:
                ComplianceToggle(
                    title: "AAA+",
                    isCompliant: wcag.level3ALarge,
                    tooltip: PikaConstants.AAAPlusText
                )),
        ]
    }

    public func touchBar(
        _: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        let foreground = delegate!.eyedroppers.foreground
        let background = delegate!.eyedroppers.background

        switch identifier {
        case NSTouchBarItem.Identifier.icon:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = NSHostingView(
                rootView: Image("StatusBarIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40.0, height: 20.0)
            )
            return item

        case NSTouchBarItem.Identifier.eyedroppers:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let foreground: NSButton = createTouchBarButton(foreground, delegate)!
            let background: NSButton = createTouchBarButton(background, delegate)!
            let stackView = NSStackView(views: [foreground, background])
            stackView.distribution = .fillEqually
            item.view = stackView
            let viewBindings: [String: NSView] = ["stackView": stackView]
            let hconstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "H:[stackView(300)]",
                options: [],
                metrics: nil,
                views: viewBindings
            )
            NSLayoutConstraint.activate(hconstraints)
            return item

        case NSTouchBarItem.Identifier.ratio:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let textField = NSTextField(labelWithString: "Contrast Ratio")
            let icon = NSImageView()
            icon.image = NSImage(named: "ellipsis.circle")

            let stackView = NSStackView(views: [icon, textField])
            item.view = stackView

            foreground.$color.sink { textField.stringValue = $0.toContrastRatioString(with: background.color) }
                .store(in: &delegate!.cancellables)
            background.$color.sink { textField.stringValue = $0.toContrastRatioString(with: foreground.color) }
                .store(in: &delegate!.cancellables)
            return item

        case NSTouchBarItem.Identifier.wcag:
            let item = NSCustomTouchBarItem(identifier: identifier)

            let stackView = NSStackView(
                views: getWCAGViews(wcag: foreground.color.toWCAGCompliance(with: background.color))
            )

            foreground.$color.sink { _ in
                stackView.setViews(self.getWCAGViews(wcag: foreground.color.toWCAGCompliance(with: background.color)), in: .leading)
                stackView.layoutSubtreeIfNeeded()
            }
            .store(in: &delegate!.cancellables)
            background.$color.sink { _ in
                stackView.setViews(self.getWCAGViews(wcag: foreground.color.toWCAGCompliance(with: background.color)), in: .leading)
                stackView.layoutSubtreeIfNeeded()
            }
            .store(in: &delegate!.cancellables)

            item.view = stackView
            return item
        default:
            return nil
        }
    }
}
