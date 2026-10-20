#if TARGET_SPARKLE
    import Cocoa
    import Combine
    import Sparkle

    /// Where an update is, as shown by Pika's inline update control.
    enum UpdateState: Equatable {
        case idle
        /// A check the user started is in progress.
        case checking
        /// An update was found and is waiting on Update or Ignore.
        case available(version: String)
        /// `progress` is nil until Sparkle reports an expected length.
        case downloading(progress: Double?)
        case extracting(progress: Double)
        case readyToRestart
        case installing
        /// Shown briefly after a check by hand that found nothing newer.
        case upToDate
        /// Only reached after a user action: Sparkle doesn't report scheduled-check failures.
        case failed(message: String)
    }

    /// The user's answer to an update, mirroring `SPUUserUpdateChoice` so the state machine can
    /// be tested without Sparkle's types (`SPUUserUpdateState` can't be constructed outside it).
    enum UpdateChoice {
        case install
        case skip
        case dismiss

        var sparkleChoice: SPUUserUpdateChoice {
            switch self {
            case .install: .install
            case .skip: .skip
            case .dismiss: .dismiss
            }
        }
    }

    /// Pika's Sparkle user driver. Instead of Sparkle's standard windows, every step of an update
    /// becomes one published `state` for the inline update control, and the control's buttons
    /// answer the reply Sparkle is waiting on. Each stored reply is called at most once.
    ///
    /// The driver never activates Pika or orders a window front: a scheduled check that finds an
    /// update only sets `needsAttention`, which flags the status bar icon.
    @MainActor
    final class PikaUpdateDriver: NSObject, ObservableObject {
        /// The app's driver. It exists before the updater does, so views can observe it from
        /// their first render whatever order launch sets things up in.
        static let shared = PikaUpdateDriver()

        @Published private(set) var state: UpdateState = .idle

        /// Set when a scheduled check finds an update, until the control has been seen.
        @Published private(set) var needsAttention = false

        /// The version on offer, for the "What's new" link and the control's tooltip.
        @Published private(set) var version: String?

        /// Starts a check by hand. Set by `UpdateController`; used by Try again.
        var checkForUpdates: () -> Void = {}

        /// Called when Sparkle asks to bring an in-progress update to the front, which happens
        /// when the user chooses "Check for Updates…" while one is already showing.
        var showUpdateInFocusHandler: () -> Void = {}

        /// How long "Up to date" shows before it's acknowledged.
        var upToDateDuration: TimeInterval = 3

        private var choiceReply: ((UpdateChoice) -> Void)?
        private var acknowledgement: (() -> Void)?
        private var retryTerminating: (() -> Void)?
        private var expectedContentLength: UInt64 = 0
        private var receivedContentLength: UInt64 = 0
        private var upToDateTimer: Timer?

        // MARK: - Sparkle events

        func userInitiatedCheckStarted() {
            state = .checking
        }

        /// `downloaded` is true when Sparkle already has the update (from an earlier session),
        /// so the only thing left to do is restart.
        func updateFound(version: String, downloaded: Bool, userInitiated: Bool,
                         reply: @escaping (UpdateChoice) -> Void)
        {
            resetPending()
            self.version = version
            choiceReply = reply
            state = downloaded ? .readyToRestart : .available(version: version)
            if !userInitiated { needsAttention = true }
        }

        func updateNotFound(acknowledgement: @escaping () -> Void) {
            resetPending()
            self.acknowledgement = acknowledgement
            state = .upToDate
            let timer = Timer(timeInterval: upToDateDuration, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.acknowledge() }
            }
            // Common modes, so it still fades while a menu is open (event tracking).
            RunLoop.main.add(timer, forMode: .common)
            upToDateTimer = timer
        }

        func updaterError(message: String, acknowledgement: @escaping () -> Void) {
            resetPending()
            self.acknowledgement = acknowledgement
            state = .failed(message: message)
        }

        func downloadStarted() {
            expectedContentLength = 0
            receivedContentLength = 0
            state = .downloading(progress: nil)
        }

        func downloadExpectedContentLength(_ length: UInt64) {
            expectedContentLength = length
            receivedContentLength = 0
            state = .downloading(progress: length > 0 ? 0 : nil)
        }

        func downloadReceivedData(ofLength length: UInt64) {
            receivedContentLength += length
            guard expectedContentLength > 0 else { return }
            let progress = min(Double(receivedContentLength) / Double(expectedContentLength), 1)
            state = .downloading(progress: progress)
        }

        func extractionStarted() {
            state = .extracting(progress: 0)
        }

        func extractionProgress(_ progress: Double) {
            state = .extracting(progress: progress)
        }

        func readyToInstall(reply: @escaping (UpdateChoice) -> Void) {
            resetPending()
            choiceReply = reply
            state = .readyToRestart
        }

        func installing(applicationTerminated: Bool, retryTerminating: @escaping () -> Void) {
            resetPending()
            // Sparkle terminates Pika itself after Restart; the retry is only needed if
            // something stopped that, in which case Restart tries again.
            self.retryTerminating = applicationTerminated ? nil : retryTerminating
            state = .installing
        }

        /// Sparkle drops the session (finished, cancelled or failed). Outstanding replies are
        /// no longer wanted, so they're dropped rather than called.
        func dismiss() {
            resetPending()
            version = nil
            needsAttention = false
            state = .idle
        }

        // MARK: - User actions

        /// Update: start downloading the version on offer.
        func update() {
            guard case .available = state else { return }
            needsAttention = false
            reply(.install)
            state = .downloading(progress: nil)
        }

        /// Ignore: skip this version on scheduled checks. A check by hand still offers it.
        func ignore() {
            guard case .available = state else { return }
            reply(.skip)
            dismiss()
        }

        /// Restart: install and relaunch.
        func restart() {
            switch state {
            case .readyToRestart:
                needsAttention = false
                reply(.install)
                state = .installing
            case .installing:
                take(&retryTerminating)?()
            default:
                break
            }
        }

        /// Try again after a failure: acknowledge the error, then check by hand.
        func retry() {
            guard case .failed = state else { return }
            acknowledge()
            checkForUpdates()
        }

        /// Dismiss a failure, or "Up to date" before it fades.
        func acknowledge() {
            upToDateTimer?.invalidate()
            upToDateTimer = nil
            take(&acknowledgement)?()
            // Sparkle follows the acknowledgement with `dismissUpdateInstallation`; go idle now
            // so the control doesn't linger on a state that's been answered.
            if case .failed = state { state = .idle }
            if state == .upToDate { state = .idle }
        }

        /// The control has been seen, so the status bar icon no longer needs flagging.
        func markSeen() {
            needsAttention = false
        }

        // MARK: - Reply bookkeeping

        private func reply(_ choice: UpdateChoice) {
            guard let reply = choiceReply else { return }
            choiceReply = nil
            reply(choice)
        }

        /// Clears a stored closure and returns it, so it's called at most once. The caller runs
        /// it after `take` returns: running it inside the `inout` access would trap if the
        /// closure re-enters the driver (an acknowledgement that dismisses straight away).
        private func take(_ closure: inout (() -> Void)?) -> (() -> Void)? {
            defer { closure = nil }
            return closure
        }

        private func resetPending() {
            upToDateTimer?.invalidate()
            upToDateTimer = nil
            choiceReply = nil
            acknowledgement = nil
            retryTerminating = nil
        }
    }

    // MARK: - SPUUserDriver

    extension PikaUpdateDriver: SPUUserDriver {
        /// `SUEnableAutomaticChecks` is set in Info.plist, so Sparkle shouldn't ask. If it does,
        /// answer with automatic checks on and show nothing.
        func show(_: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
            reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
        }

        func showUserInitiatedUpdateCheck(cancellation _: @escaping () -> Void) {
            userInitiatedCheckStarted()
        }

        func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState,
                             reply: @escaping (SPUUserUpdateChoice) -> Void)
        {
            updateFound(version: appcastItem.displayVersionString,
                        downloaded: state.stage != .notDownloaded,
                        userInitiated: state.userInitiated) { reply($0.sparkleChoice) }
        }

        /// Release notes aren't shown in-app; "What's new" links to the changelog instead.
        func showUpdateReleaseNotes(with _: SPUDownloadData) {}

        func showUpdateReleaseNotesFailedToDownloadWithError(_: Error) {}

        func showUpdateNotFoundWithError(_: Error, acknowledgement: @escaping () -> Void) {
            updateNotFound(acknowledgement: acknowledgement)
        }

        func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
            updaterError(message: error.localizedDescription, acknowledgement: acknowledgement)
        }

        func showDownloadInitiated(cancellation _: @escaping () -> Void) {
            downloadStarted()
        }

        func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
            downloadExpectedContentLength(expectedContentLength)
        }

        func showDownloadDidReceiveData(ofLength length: UInt64) {
            downloadReceivedData(ofLength: length)
        }

        func showDownloadDidStartExtractingUpdate() {
            extractionStarted()
        }

        func showExtractionReceivedProgress(_ progress: Double) {
            extractionProgress(progress)
        }

        func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
            readyToInstall { reply($0.sparkleChoice) }
        }

        func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool,
                                  retryTerminatingApplication: @escaping () -> Void)
        {
            installing(applicationTerminated: applicationTerminated, retryTerminating: retryTerminatingApplication)
        }

        func showUpdateInstalledAndRelaunched(_: Bool, acknowledgement: @escaping () -> Void) {
            acknowledgement()
        }

        func showUpdateInFocus() {
            showUpdateInFocusHandler()
        }

        func dismissUpdateInstallation() {
            dismiss()
        }
    }

    // MARK: - Controller

    /// Owns Pika's Sparkle updater, with `PikaUpdateDriver` in place of Sparkle's standard
    /// windows. `AppDelegate` stays the updater delegate, so it still picks the stable or
    /// beta feed.
    @MainActor
    final class UpdateController {
        let driver = PikaUpdateDriver.shared
        let updater: SPUUpdater
        private var retryObservation: NSKeyValueObservation?
        private var seenObservation: NSObjectProtocol?

        init(delegate: SPUUpdaterDelegate) {
            updater = SPUUpdater(
                hostBundle: .main,
                applicationBundle: .main,
                userDriver: driver,
                delegate: delegate
            )
            driver.checkForUpdates = { [weak self] in self?.checkForUpdatesWhenReady() }
            observeSeen()
        }

        /// The control counts as seen once Pika's window or popover comes to the front with it
        /// showing, which clears the status bar flag.
        private func observeSeen() {
            seenObservation = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let window = notification.object as? NSWindow,
                          let appDelegate = AppDelegate.shared else { return }
                    let showsControl = window === appDelegate.windowCoordinator.pikaWindow
                        || appDelegate.statusBarController.isPopoverShown
                    if showsControl { self?.driver.markSeen() }
                }
            }
        }

        /// Starts the updater, which schedules automatic checks.
        func start() {
            do {
                try updater.start()
            } catch {
                NSLog("Pika: couldn't start the updater: \(error.localizedDescription)")
            }
        }

        /// A check by hand. Its result shows in the inline control.
        func checkForUpdates() {
            updater.checkForUpdates()
        }

        /// After a failure is acknowledged, Sparkle tears the session down asynchronously and
        /// ignores checks until it's done, so wait for `canCheckForUpdates` before retrying.
        private func checkForUpdatesWhenReady() {
            if updater.canCheckForUpdates {
                updater.checkForUpdates()
                return
            }
            retryObservation = updater.observe(\.canCheckForUpdates) { [weak self] updater, _ in
                guard updater.canCheckForUpdates else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self, retryObservation != nil else { return }
                    retryObservation = nil
                    updater.checkForUpdates()
                }
            }
        }
    }
#endif
