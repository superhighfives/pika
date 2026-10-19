#if TARGET_SPARKLE
    import Foundation

    // MARK: - Debug states

    #if DEBUG
        extension PikaUpdateDriver {
            /// Shows a state in the inline control with stand-in replies, so the UX can be checked
            /// without a feed (`pika://debug/update/<state>`). From "available", Update walks a
            /// simulated download to Restart, and Restart pretends to install, then goes idle.
            func debugShow(_ name: String) {
                dismiss()
                switch name {
                case "checking":
                    userInitiatedCheckStarted()
                case "available":
                    updateFound(version: "9.9.9", downloaded: false, userInitiated: false) { [weak self] choice in
                        if choice == .install { self?.debugSimulateDownload() }
                    }
                case "downloading":
                    debugSimulateDownload()
                case "ready":
                    debugReadyToInstall()
                case "installing":
                    installing(applicationTerminated: true) {}
                case "uptodate":
                    updateNotFound { [weak self] in self?.dismiss() }
                case "failed":
                    updaterError(message: "The network connection was lost.") { [weak self] in self?.dismiss() }
                default:
                    break
                }
            }

            private func debugSimulateDownload() {
                let total: UInt64 = 5_000_000
                downloadStarted()
                downloadExpectedContentLength(total)
                var received: UInt64 = 0
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    MainActor.assumeIsolated {
                        guard let self, case .downloading = self.state else { return timer.invalidate() }
                        received += total / 30
                        self.downloadReceivedData(ofLength: total / 30)
                        guard received >= total else { return }
                        timer.invalidate()
                        self.extractionStarted()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                            self?.debugReadyToInstall()
                        }
                    }
                }
            }

            private func debugReadyToInstall() {
                readyToInstall { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self?.dismiss() }
                }
            }
        }
    #endif
#endif
