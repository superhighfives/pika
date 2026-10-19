#if TARGET_SPARKLE
    import Cocoa

    // MARK: - Status bar menu

    /// A menu item that runs a closure, for the update items in the status bar menu.
    private final class ClosureMenuItem: NSMenuItem {
        private let handler: () -> Void

        init(title: String, handler: @escaping () -> Void) {
            self.handler = handler
            super.init(title: title, action: #selector(run), keyEquivalent: "")
            target = self
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) { fatalError("init(coder:) is not supported") }

        @objc private func run() { handler() }
    }

    extension PikaUpdateDriver {
        /// The update control as status bar menu items, for the menu-only placement.
        var statusMenuItems: [NSMenuItem] {
            func label(_ title: String) -> NSMenuItem {
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                return item
            }
            switch state {
            case .idle:
                return []
            case .checking:
                return [label(PikaText.textUpdateChecking)]
            case let .available(version):
                markSeen()
                let title = label("\(PikaText.textUpdateAvailable) (\(version))")
                return [
                    title,
                    ClosureMenuItem(title: PikaText.textUpdateUpdate) { [weak self] in self?.update() },
                    ClosureMenuItem(title: PikaText.textUpdateIgnore) { [weak self] in self?.ignore() },
                    ClosureMenuItem(title: "\(PikaText.textUpdateWhatsNew)…") {
                        if let url = PikaConstants.changelogURL(version: version) { NSWorkspace.shared.open(url) }
                    },
                ]
            case let .downloading(progress):
                let percent = progress.map { " \(Int($0 * 100))%" } ?? ""
                return [label("\(PikaText.textUpdateDownloading)\(percent)")]
            case .extracting:
                return [label(PikaText.textUpdateDownloading)]
            case .readyToRestart:
                markSeen()
                return [ClosureMenuItem(title: PikaText.textUpdateRestart) { [weak self] in self?.restart() }]
            case .installing:
                return [label(PikaText.textUpdateInstalling)]
            case .upToDate:
                return [label(PikaText.textUpdateUpToDate)]
            case let .failed(message):
                let title = label(PikaText.textUpdateFailed)
                title.toolTip = message
                return [
                    title,
                    ClosureMenuItem(title: PikaText.textUpdateTryAgain) { [weak self] in self?.retry() },
                    ClosureMenuItem(title: PikaText.textUpdateDismiss) { [weak self] in self?.acknowledge() },
                ]
            }
        }
    }
#endif
