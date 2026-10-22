#if TARGET_SPARKLE
    import SwiftUI

    /// The live update control along the bottom of the window and the popover.
    struct InlineUpdateControl: View {
        var body: some View {
            UpdateControl(driver: .shared)
        }
    }

    /// Shows the driver's `UpdateState` and answers it: Update or Ignore, a spinner while
    /// downloading, Restart once it's ready, and a failure that stays until it's dismissed.
    struct UpdateControl: View {
        @ObservedObject var driver: PikaUpdateDriver

        var body: some View {
            // A real container rather than `Group`: modifiers on a `Group` attach to its child,
            // so the animation left with the bar and its removal was a hard cut.
            VStack(spacing: 0) {
                if driver.state != .idle { bar }
            }
            .animation(.easeInOut(duration: 0.2), value: driver.state)
        }

        private var bar: some View {
            VStack(spacing: 0) {
                AdaptiveDivider()
                HStack(spacing: 8) {
                    icon
                    title
                    if case let .available(version) = driver.state {
                        WhatsNewLink(version: version)
                    }
                    Spacer(minLength: 8)
                    if let progress {
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
            case .checking, .installing, .downloading, .extracting:
                ProgressView().controlSize(.mini)
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
                Text(PikaText.textUpdateAvailable)
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

        /// Download progress, once Sparkle knows the expected length.
        private var progress: Double? {
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

    /// "Version 2.1.0", which opens that version's changelog entry ("What's new").
    private struct WhatsNewLink: View {
        let version: String
        @State private var hovering = false

        var body: some View {
            Button {
                if let url = PikaConstants.changelogURL(version: version) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text(String(format: PikaText.textUpdateVersion, version))
                    .foregroundStyle(hovering ? Color.primary : Color.secondary)
                    .underline(hovering)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hovering = $0 }
            .help(PikaText.textUpdateWhatsNew)
            .accessibilityHint(PikaText.textUpdateWhatsNew)
        }
    }

    /// A compact capsule button sized for the bar.
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
        /// Every state the control can show.
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
                VStack(spacing: 10) {
                    ForEach(states, id: \.0) { _, setUp in
                        UpdateControl(driver: driver(setUp))
                    }
                }
                .frame(width: 400)
                .padding(.vertical)
            }
        }
    #endif
#endif
