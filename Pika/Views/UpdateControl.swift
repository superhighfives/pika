#if TARGET_SPARKLE
    import SwiftUI

    /// Where the inline update control lives. While the placement is being chosen, a debug
    /// build can switch between them live (`pika://debug/placement/<name>`); a release build
    /// always uses the toolbar.
    enum UpdatePlacement: String, CaseIterable {
        /// A capsule in the toolbar of the window and the popover.
        case toolbar
        /// A slim bar along the bottom of the window and the popover.
        case bar
        /// Items at the top of the status bar menu only.
        case menu

        static let debugDefaultsKey = "debugUpdatePlacement"

        static var current: UpdatePlacement {
            #if DEBUG
                UserDefaults.standard.string(forKey: debugDefaultsKey).flatMap(Self.init) ?? .toolbar
            #else
                .toolbar
            #endif
        }
    }

    /// The live update control for one placement, or nothing if that placement isn't the
    /// current one (or there's no updater, as in previews).
    struct InlineUpdateControl: View {
        let placement: UpdatePlacement
        @AppStorage(UpdatePlacement.debugDefaultsKey) private var placementName = UpdatePlacement.toolbar.rawValue

        var body: some View {
            if isCurrent, let driver = AppDelegate.shared?.updateController?.driver {
                UpdateControl(driver: driver, style: placement == .bar ? .bar : .capsule)
            }
        }

        /// Reads the stored name (not `UpdatePlacement.current`) so the view updates when a
        /// debug build switches placement.
        private var isCurrent: Bool {
            #if DEBUG
                placementName == placement.rawValue
            #else
                placement == .toolbar
            #endif
        }
    }

    /// Shows the driver's `UpdateState` and answers it: Update or Ignore, a spinner while
    /// downloading, Restart once it's ready, and a failure that stays until it's dismissed.
    struct UpdateControl: View {
        enum Style {
            case capsule
            case bar
        }

        @ObservedObject var driver: PikaUpdateDriver
        let style: Style

        var body: some View {
            Group {
                if driver.state != .idle {
                    switch style {
                    case .capsule: capsule
                    case .bar: bar
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: driver.state)
        }

        // MARK: - Styles

        private var capsule: some View {
            HStack(spacing: 6) {
                icon
                title
                actions
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.leading, 8)
            .padding(.trailing, hasActions ? 3 : 10)
            .frame(height: 22)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12)))
            .fixedSize()
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }

        private var bar: some View {
            VStack(spacing: 0) {
                AdaptiveDivider()
                HStack(spacing: 8) {
                    icon
                    title
                    if case let .available(version) = driver.state {
                        Text(String(format: PikaText.textUpdateVersion, version))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if let progress = linearProgress {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .controlSize(.small)
                            .frame(width: 100)
                    }
                    actions
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(AdaptivePanelBackground())
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // MARK: - Pieces

        @ViewBuilder private var icon: some View {
            switch driver.state {
            case .idle:
                EmptyView()
            case .checking, .installing:
                ProgressView().controlSize(.mini)
            case let .downloading(progress):
                if style == .capsule, let progress {
                    ProgressView(value: progress).progressViewStyle(.circular).controlSize(.mini)
                } else {
                    ProgressView().controlSize(.mini)
                }
            case let .extracting(progress):
                if style == .capsule {
                    ProgressView(value: progress).progressViewStyle(.circular).controlSize(.mini)
                } else {
                    ProgressView().controlSize(.mini)
                }
            case .available:
                symbol("arrow.down.circle.fill", .accentColor)
            case .readyToRestart:
                symbol("arrow.clockwise.circle.fill", .accentColor)
            case .upToDate:
                symbol("checkmark.circle.fill", .green)
            case .failed:
                symbol("exclamationmark.triangle.fill", .orange)
            }
        }

        @ViewBuilder private var title: some View {
            switch driver.state {
            case .idle:
                EmptyView()
            case .checking:
                Text(PikaText.textUpdateChecking)
            case .available:
                WhatsNewLink(version: driver.version)
            case .downloading, .extracting:
                Text(PikaText.textUpdateDownloading)
            case .readyToRestart:
                // The Restart button carries the message.
                EmptyView()
            case .installing:
                Text(PikaText.textUpdateInstalling)
            case .upToDate:
                Text(PikaText.textUpdateUpToDate)
            case let .failed(message):
                Text(PikaText.textUpdateFailed).help(message)
            }
        }

        @ViewBuilder private var actions: some View {
            switch driver.state {
            case .available:
                ActionButton(title: PikaText.textUpdateUpdate, prominent: true) { driver.update() }
                ActionButton(title: PikaText.textUpdateIgnore) { driver.ignore() }
            case .readyToRestart:
                ActionButton(title: PikaText.textUpdateRestart, prominent: true) { driver.restart() }
            case .failed:
                ActionButton(title: PikaText.textUpdateTryAgain) { driver.retry() }
                DismissButton { driver.acknowledge() }
            default:
                EmptyView()
            }
        }

        private var hasActions: Bool {
            switch driver.state {
            case .available, .readyToRestart, .failed: true
            default: false
            }
        }

        /// The bar shows download progress as a line; the capsule fills its spinner instead.
        private var linearProgress: Double? {
            switch driver.state {
            case let .downloading(progress): progress
            case let .extracting(progress): progress
            default: nil
            }
        }

        private func symbol(_ name: String, _ color: Color) -> some View {
            Image(systemName: name)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .accessibilityHidden(true)
        }
    }

    /// "Update available", which opens that version's changelog entry ("What's new").
    private struct WhatsNewLink: View {
        let version: String?
        @State private var hovering = false

        var body: some View {
            Button {
                if let version, let url = PikaConstants.changelogURL(version: version) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text(PikaText.textUpdateAvailable)
                    .underline(hovering)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hovering = $0 }
            .help(helpText)
            .accessibilityHint(PikaText.textUpdateWhatsNew)
        }

        private var helpText: String {
            guard let version else { return PikaText.textUpdateWhatsNew }
            return "\(String(format: PikaText.textUpdateVersion, version)) · \(PikaText.textUpdateWhatsNew)"
        }
    }

    /// A compact capsule button sized for the toolbar and the bar alike.
    private struct ActionButton: View {
        let title: String
        var prominent = false
        let action: () -> Void
        @State private var hovering = false

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 11, weight: prominent ? .semibold : .medium))
                    .foregroundStyle(prominent ? Color.white : Color.primary)
                    .padding(.horizontal, 8)
                    .frame(height: 16)
                    .background(
                        Capsule().fill(prominent
                            ? Color.accentColor.opacity(hovering ? 0.85 : 1)
                            : Color.primary.opacity(hovering ? 0.16 : 0.1))
                    )
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hovering = $0 }
        }
    }

    private struct DismissButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(PikaText.textUpdateDismiss)
            .accessibilityLabel(PikaText.textUpdateDismiss)
        }
    }

    // MARK: - Previews

    #if DEBUG
        /// Every state the control can show, in both styles.
        struct UpdateControl_Previews: PreviewProvider {
            private static let states: [(String, (PikaUpdateDriver) -> Void)] = [
                ("checking", { $0.userInitiatedCheckStarted() }),
                ("available", { $0.updateFound(version: "2.1.0", downloaded: false, userInitiated: false) { _ in } }),
                ("downloading", { $0.downloadExpectedContentLength(100); $0.downloadReceivedData(ofLength: 40) }),
                ("ready", { $0.readyToInstall { _ in } }),
                ("installing", { $0.installing(applicationTerminated: true) {} }),
                ("up to date", { $0.updateNotFound {} }),
                ("failed", { $0.updaterError(message: "The network connection was lost.") {} }),
            ]

            private static func driver(_ setUp: (PikaUpdateDriver) -> Void) -> PikaUpdateDriver {
                let driver = PikaUpdateDriver()
                driver.upToDateDuration = .infinity
                setUp(driver)
                return driver
            }

            static var previews: some View {
                Group {
                    VStack(alignment: .trailing, spacing: 10) {
                        ForEach(states, id: \.0) { _, setUp in
                            UpdateControl(driver: driver(setUp), style: .capsule)
                        }
                    }
                    .padding()
                    .previewDisplayName("Capsule")

                    VStack(spacing: 10) {
                        ForEach(states, id: \.0) { _, setUp in
                            UpdateControl(driver: driver(setUp), style: .bar)
                        }
                    }
                    .frame(width: 400)
                    .padding(.vertical)
                    .previewDisplayName("Bar")
                }
            }
        }
    #endif
#endif
