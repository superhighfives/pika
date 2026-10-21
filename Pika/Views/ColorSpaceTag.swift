import AppKit
import SwiftUI

/// Names the colour space the readout is in when it's one people wouldn't assume, i.e. neither
/// sRGB nor Display P3 (see `ColorSpacePreference.isCommon`). A hex read in a display profile
/// won't match the same colour's hex in CSS, so a mismatch is noticed here, and can be fixed
/// from the menu this opens.
struct ColorSpaceTag: View {
    let space: NSColorSpace
    let uiColor: NSColor

    private var name: String { ColorSpacePreference.name(of: space) }

    var body: some View {
        Button(action: showMenu) {
            HStack(spacing: 2) {
                Text(name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color(uiColor))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(Color(uiColor).opacity(0.18)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(String(format: PikaText.textSpaceTag, name))
    }

    /// An AppKit menu rather than a SwiftUI `Menu`: a borderless `Menu` on macOS draws its label
    /// as a plain button title, dropping the pill styling.
    private func showMenu() {
        let menu = NSMenu()
        let current = ColorSpacePreference.current
        let options: [(String, ColorSpaceOption)] = [
            ("sRGB", .space(.sRGB)),
            ("Display P3", .space(.displayP3)),
            (String(format: PikaText.textSpaceDisplay, ColorSpacePreference.displaySpaceName ?? "—"), .matchDisplay),
        ]
        for (title, option) in options {
            menu.addItem(ClosureMenuItem(title: title, checked: option == current) {
                ColorSpacePreference.select(option)
            })
        }
        // A space chosen in Preferences that isn't one of the three above.
        if case let .space(space) = current, !ColorSpacePreference.isCommon(space) {
            menu.addItem(ClosureMenuItem(title: space.localizedName ?? "", checked: true) {})
        }
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: PikaText.textSpaceMismatch + "…") {
            NSApp.sendAction(#selector(AppDelegate.openColorMatchWindow), to: nil, from: nil)
        })
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

/// A menu item that runs a closure, for menus built in code outside the responder chain.
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, checked: Bool = false, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        state = checked ? .on : .off
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func run() {
        handler()
    }
}
