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
    @Default(.contrastStandard) var contrastStandard
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

        let colorForeground: NSButton = createTouchBarColorButton(foreground)!
        let copyForeground: NSButton = createTouchBarCopyButton(action: #selector(AppDelegate.triggerCopyForeground))!
        let foregroundStackView = NSStackView(views: [colorForeground, copyForeground])
        foregroundStackView.distribution = .fillProportionally
        foregroundStackView.spacing = 1

        let colorBackground: NSButton = createTouchBarColorButton(background)!
        let copyBackground: NSButton = createTouchBarCopyButton(action: #selector(AppDelegate.triggerCopyBackground))!
        let backgroundStackView = NSStackView(views: [colorBackground, copyBackground])
        backgroundStackView.distribution = .fillProportionally
        backgroundStackView.spacing = 1

        let stackView = NSStackView(views: [foregroundStackView, backgroundStackView])
        stackView.distribution = .fillEqually
        item.view = stackView
        let viewBindings: [String: NSView] = ["stackView": stackView]
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[stackView(370)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)
        return item
    }

    func updateButton(button: NSButton, color: NSColor) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            button.title = color.toFormat(format: Defaults[.colorFormat])
            button.bezelColor = Int(round(color.toHSBComponents().b * 100)) <= 20
                ? NSColor(r: 35, g: 35, b: 35, a: 1)
                : color
        }
    }

    func createTouchBarColorButton(_ eyedropper: Eyedropper) -> NSButton? {
        let button = NSButton(title: "", target: nil, action: eyedropper.type.pickSelector)
        button.setButtonType(NSButton.ButtonType.toggle)
        eyedropper.$color.sink { color in
            self.updateButton(button: button, color: color)
        }
        .store(in: &cancellables)
        Defaults.observe(.colorFormat) { _ in
            self.updateButton(button: button, color: eyedropper.color)
        }.tieToLifetime(of: self)
        return button
    }

    func createTouchBarCopyButton(action: Selector) -> NSButton? {
        let button = NSButton(
            image: NSImage(named: "doc.on.doc")!,
            target: nil,
            action: action
        )
        let viewBindings: [String: NSView] = ["button": button]
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[button(35)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)
        return button
    }

    func createContrastRatio(
        _ identifier: NSTouchBarItem.Identifier,
        _ foreground: Eyedropper,
        _ background: Eyedropper
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        let textField = NSTextField(labelWithString: "")
        let icon = NSHostingView(rootView:
            IconImage(name: "circle.lefthalf.fill", resizable: true).frame(width: 13.0, height: 13.0)
        )

        let stackView = NSStackView(views: [icon, textField])
        let view = NSView()
        view.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        item.view = view

        let viewBindings: [String: NSView] = ["stackView": view]
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[stackView(70)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)

        foreground.$color.sink { textField.stringValue = self.contrastStandard == .wcag ? $0.toContrastRatioString(with: background.color) :
            $0.toAPCAcontrastValue(with: background.color)
        }
        .store(in: &cancellables)
        background.$color.sink { textField.stringValue = self.contrastStandard == .wcag ? $0.toContrastRatioString(with: background.color) :
            $0.toAPCAcontrastValue(with: background.color)
        }
        .store(in: &cancellables)
        return item
    }

    func createComplianceGroup(
        _ identifier: NSTouchBarItem.Identifier,
        _ foreground: Eyedropper,
        _ background: Eyedropper
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let complianceType = Defaults[.contrastStandard] == .wcag ? "WCAG" : "APCA"
        let colorCompliance: Any = Defaults[.contrastStandard] == .wcag ?
            foreground.color.toWCAGCompliance(with: background.color) as Any :
            foreground.color.toAPCACompliance(with: background.color) as Any

        let complianceViews = NSHostingView(rootView:
            ComplianceToggleGroup(
                colorCompliance: colorCompliance,
                complianceType: complianceType,
                size: .small,
                theme: Defaults[.combineCompliance] ? .contrast : .weight
            ))

        Defaults.publisher(keys: .combineCompliance, .contrastStandard).sink { _ in
            let complianceType = Defaults[.contrastStandard] == .wcag ? "WCAG" : "APCA"
            let colorCompliance: Any = Defaults[.contrastStandard] == .wcag ?
                foreground.color.toWCAGCompliance(with: background.color) as Any :
                foreground.color.toAPCACompliance(with: background.color) as Any
            complianceViews.rootView = ComplianceToggleGroup(
                colorCompliance: colorCompliance,
                complianceType: complianceType,
                size: .small,
                theme: Defaults[.combineCompliance] ? .contrast : .weight
            )
        }
        .store(in: &cancellables)
        foreground.$color.sink { newColor in
            let complianceType = Defaults[.contrastStandard] == .wcag ? "WCAG" : "APCA"
            let colorCompliance: Any = Defaults[.contrastStandard] == .wcag ?
                newColor.toWCAGCompliance(with: background.color) as Any :
                newColor.toAPCACompliance(with: background.color) as Any
            complianceViews.rootView = ComplianceToggleGroup(
                colorCompliance: colorCompliance,
                complianceType: complianceType,
                size: .small,
                theme: Defaults[.combineCompliance] ? .contrast : .weight
            )
        }
        .store(in: &cancellables)
        background.$color.sink { newColor in
            let complianceType = Defaults[.contrastStandard] == .wcag ? "WCAG" : "APCA"
            let colorCompliance: Any = Defaults[.contrastStandard] == .wcag ?
                foreground.color.toWCAGCompliance(with: newColor) as Any :
                foreground.color.toAPCACompliance(with: newColor) as Any
            complianceViews.rootView = ComplianceToggleGroup(
                colorCompliance: colorCompliance,
                complianceType: complianceType,
                size: .small,
                theme: Defaults[.combineCompliance] ? .contrast : .weight
            )
        }
        .store(in: &cancellables)
        item.view = complianceViews
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
            return createComplianceGroup(identifier, foreground, background)

        default:
            return nil
        }
    }
}
