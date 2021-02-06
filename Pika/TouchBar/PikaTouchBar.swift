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

class PikaTouchBarController: NSWindowController, NSTouchBarDelegate {
    var cancellables = Set<AnyCancellable>()

    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.eyedroppers, .ratio, .wcag]
        return touchBar
    }

    func createIcon(_ identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = NSHostingView(
            rootView: Image("StatusBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30.0, height: 20.0)
                .opacity(0.8)
        )
        return item
    }

    func createEyedropperButtons(
        _ identifier: NSTouchBarItem.Identifier,
        _ foreground: Eyedropper,
        _ background: Eyedropper
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        let foreground: NSButton = createTouchBarButton(foreground)!
        let background: NSButton = createTouchBarButton(background)!
        let stackView = NSStackView(views: [foreground, background])
        stackView.distribution = .fillEqually
        item.view = stackView
        let viewBindings: [String: NSView] = ["stackView": stackView]
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[stackView(340)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)
        return item
    }

    func updateButton(button: NSButton, eyedropper: Eyedropper) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            button.title = eyedropper.color.toFormat(format: Defaults[.colorFormat])
            button.contentTintColor = eyedropper.getUIColor()
            button.bezelColor = Int(round(eyedropper.color.toHSBComponents().b * 100)) <= 20
                ? NSColor(r: 20, g: 20, b: 20, a: 1)
                : eyedropper.color
        }
    }

    func createTouchBarButton(_ eyedropper: Eyedropper) -> NSButton? {
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
        .store(in: &cancellables)
        Defaults.observe(.colorFormat) { _ in
            self.updateButton(button: button, eyedropper: eyedropper)
        }.tieToLifetime(of: self)
        return button
    }

    func createContrastRatio(
        _ identifier: NSTouchBarItem.Identifier,
        _ foreground: Eyedropper,
        _ background: Eyedropper
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        let textField = NSTextField(labelWithString: "Contrast Ratio")
        let icon = NSHostingView(rootView: IconImage(name: "circle.lefthalf.fill"))

        let stackView = NSStackView(views: [icon, textField])
        let view = NSView()
        view.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        item.view = view

        let viewBindings: [String: NSView] = ["stackView": view]
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[stackView(80)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)

        foreground.$color.sink { textField.stringValue = $0.toContrastRatioString(with: background.color) }
            .store(in: &cancellables)
        background.$color.sink { textField.stringValue = $0.toContrastRatioString(with: foreground.color) }
            .store(in: &cancellables)
        return item
    }

    func createWCAGComplianceGroup(
        _ identifier: NSTouchBarItem.Identifier,
        _ foreground: Eyedropper,
        _ background: Eyedropper
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let colorWCAGCompliance = foreground.color.toWCAGCompliance(with: background.color)

        let wcagViews = NSHostingView(rootView:
            ComplianceToggleGroup(
                colorWCAGCompliance: colorWCAGCompliance,
                size: .small
            ))

        foreground.$color.sink {
            let colorWCAGCompliance = $0.toWCAGCompliance(with: background.color)
            wcagViews.rootView.colorWCAGCompliance = colorWCAGCompliance
        }
        .store(in: &cancellables)
        background.$color.sink {
            let colorWCAGCompliance = $0.toWCAGCompliance(with: foreground.color)
            wcagViews.rootView.colorWCAGCompliance = colorWCAGCompliance
        }
        .store(in: &cancellables)
        item.view = wcagViews
        return item
    }

    func touchBar(
        _: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        let foreground = delegate!.eyedroppers.foreground
        let background = delegate!.eyedroppers.background

        switch identifier {
        case NSTouchBarItem.Identifier.icon:
            let item = createIcon(identifier)
            return item

        case NSTouchBarItem.Identifier.eyedroppers:
            let item = createEyedropperButtons(identifier, foreground, background)
            return item

        case NSTouchBarItem.Identifier.ratio:
            let item = createContrastRatio(identifier, foreground, background)
            return item

        case NSTouchBarItem.Identifier.wcag:
            return createWCAGComplianceGroup(identifier, foreground, background)
        default:
            return nil
        }
    }
}
