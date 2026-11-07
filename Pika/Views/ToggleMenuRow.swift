import AppKit

/// A menu's toggle rows, and which one is highlighted. A menu doesn't redraw a custom row as its
/// own highlight moves, and the rows take the menu's keys (see `ToggleMenuRow`), so the rows keep
/// the highlight themselves: the pointer and the arrow keys both move it.
final class ToggleMenuRows {
    private(set) var all: [ToggleMenuRow] = []
    private(set) var highlighted: ToggleMenuRow? {
        didSet {
            oldValue?.needsDisplay = true
            highlighted?.needsDisplay = true
        }
    }

    func add(_ row: ToggleMenuRow) { all.append(row) }

    func highlight(_ row: ToggleMenuRow?) { highlighted = row }

    func unhighlight(_ row: ToggleMenuRow) {
        if highlighted === row { highlighted = nil }
    }

    /// A key typed while the menu is open. Returns false to leave it to the menu (Esc closes it).
    func handle(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function])
        guard modifiers.isEmpty else { return false }
        switch event.specialKey {
        case .downArrow?:
            move(by: 1)
        case .upArrow?:
            move(by: -1)
        case .carriageReturn?, .enter?:
            // With nothing highlighted, Return closes the menu as usual.
            guard let highlighted else { return false }
            highlighted.toggleFromKey()
        default:
            // A row's key toggles it, and so does Space on the highlighted row.
            let key = event.charactersIgnoringModifiers?.lowercased()
            if key == " ", let highlighted {
                highlighted.toggleFromKey()
            } else if let row = all.first(where: { $0.key.lowercased() == key }) {
                row.toggleFromKey()
            } else {
                return false
            }
        }
        return true
    }

    /// Down from the top and up from the bottom, like a standard menu, wrapping at the ends.
    private func move(by step: Int) {
        guard !all.isEmpty else { return }
        let start = highlighted.flatMap { row in all.firstIndex { $0 === row } }
        let next = start.map { ($0 + step + all.count) % all.count } ?? (step > 0 ? 0 : all.count - 1)
        highlighted = all[next]
    }
}

/// A checkable menu row that toggles in place without closing its menu. Draws what a standard
/// item would: a checkmark, the title, the key on the right, and the highlight under the pointer.
final class ToggleMenuRow: NSView {
    private let isOn: () -> Bool
    private let toggle: () -> Void
    private let check = NSImageView()
    private let titleLabel: NSTextField
    private let keyLabel: NSTextField
    private weak var rows: ToggleMenuRows?
    let key: String

    init(
        title: String,
        key: String,
        rows: ToggleMenuRows,
        isOn: @escaping () -> Bool,
        toggle: @escaping () -> Void
    ) {
        self.isOn = isOn
        self.toggle = toggle
        self.key = key
        self.rows = rows
        titleLabel = NSTextField(labelWithString: title)
        keyLabel = NSTextField(labelWithString: key)
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        autoresizingMask = [.width]

        let font = NSFont.menuFont(ofSize: 0)
        titleLabel.font = font
        keyLabel.font = font
        keyLabel.alignment = .right
        check.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: font.pointSize - 1, weight: .semibold))

        for view in [check, titleLabel, keyLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            check.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            check.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            keyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 24),
            keyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            keyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.checkBox)
        setAccessibilityLabel(title)
        rows.add(self)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var isHighlighted: Bool { rows?.highlighted === self }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with _: NSEvent) { rows?.highlight(self) }

    override func mouseExited(with _: NSEvent) { rows?.unhighlight(self) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // The menu sends the keys typed while it's open to its first responder, so one row
        // takes them all and hands them to the rows.
        if let window, !(window.firstResponder is ToggleMenuRow) {
            window.makeFirstResponder(self)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if rows?.handle(event) != true { super.keyDown(with: event) }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        rows?.handle(event) == true || super.performKeyEquivalent(with: event)
    }

    /// The state just set by a click, until the setting itself is read again on the next open.
    private var shownOn: Bool?

    private func refresh() {
        let on = shownOn ?? isOn()
        check.isHidden = !on
        setAccessibilityValue(on)
        let highlighted = isHighlighted
        titleLabel.textColor = highlighted ? .selectedMenuItemTextColor : .labelColor
        keyLabel.textColor = highlighted ? .selectedMenuItemTextColor : .secondaryLabelColor
        check.contentTintColor = highlighted ? .selectedMenuItemTextColor : .labelColor
    }

    override func draw(_ dirtyRect: NSRect) {
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 5, yRadius: 5).fill()
        }
        refresh()
        super.draw(dirtyRect)
    }

    override func mouseUp(with _: NSEvent) {
        flip()
    }

    /// The row's key, pressed while the menu is open.
    func toggleFromKey() {
        flip()
    }

    override func accessibilityPerformPress() -> Bool {
        flip()
        return true
    }

    /// Toggles the setting and shows it at once. While a menu is open the app runs the menu's own
    /// event loop, which holds back queued work and SwiftUI's redraws until it closes, so a click
    /// looked like it did nothing. The check is set from the flip rather than read back.
    private func flip() {
        let wasOn = isOn()
        toggle()
        shownOn = !wasOn
        refresh()
        display()
        // Run the app's normal run loop for as long as the window's transitions take (0.3 s at
        // most), so SwiftUI applies the change and animates it behind the menu now; in the menu's
        // own loop an animation starts but doesn't advance until the menu closes.
        let settle = Date(timeIntervalSinceNow: 0.35)
        while Date() < settle {
            RunLoop.main.run(mode: .default, before: settle)
        }
    }
}
