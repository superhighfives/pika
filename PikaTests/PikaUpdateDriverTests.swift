@testable import Pika
import XCTest

/// The inline update flow's state machine. Each test feeds `PikaUpdateDriver` Sparkle's
/// callbacks in the order Sparkle sends them, then checks the published state and that every
/// reply Sparkle is waiting on is answered exactly once.
@MainActor
final class PikaUpdateDriverTests: XCTestCase {
    private var driver: PikaUpdateDriver!
    private var choices: [UpdateChoice] = []
    private var acknowledgements = 0

    override func setUp() async throws {
        driver = PikaUpdateDriver()
        choices = []
        acknowledgements = 0
    }

    private func recordChoice(_ choice: UpdateChoice) { choices.append(choice) }
    private func recordAcknowledgement() { acknowledgements += 1 }

    // MARK: - Available → download → restart

    func test_fullUpdate_walksEveryState_andRepliesInstallTwice() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        XCTAssertEqual(driver.state, .available(version: "2.1.0"))
        XCTAssertEqual(driver.version, "2.1.0")

        driver.update()
        XCTAssertEqual(choices, [.install])

        driver.downloadStarted()
        XCTAssertEqual(driver.state, .downloading(progress: nil))
        driver.downloadExpectedContentLength(200)
        XCTAssertEqual(driver.state, .downloading(progress: 0))
        driver.downloadReceivedData(ofLength: 50)
        XCTAssertEqual(driver.state, .downloading(progress: 0.25))
        driver.downloadReceivedData(ofLength: 150)
        XCTAssertEqual(driver.state, .downloading(progress: 1))

        driver.extractionStarted()
        XCTAssertEqual(driver.state, .extracting(progress: 0))
        driver.extractionProgress(0.5)
        XCTAssertEqual(driver.state, .extracting(progress: 0.5))

        driver.readyToInstall(reply: recordChoice)
        XCTAssertEqual(driver.state, .readyToRestart)

        driver.restart()
        XCTAssertEqual(choices, [.install, .install])
        XCTAssertEqual(driver.state, .installing)

        driver.installing(applicationTerminated: true, retryTerminating: { XCTFail("retry not needed") })
        driver.restart()
        XCTAssertEqual(driver.state, .installing)
    }

    func test_download_withoutExpectedLength_staysIndeterminate() {
        driver.downloadStarted()
        driver.downloadReceivedData(ofLength: 1000)
        XCTAssertEqual(driver.state, .downloading(progress: nil))
    }

    func test_download_overreportedData_capsAtOne() {
        driver.downloadExpectedContentLength(100)
        driver.downloadReceivedData(ofLength: 150)
        XCTAssertEqual(driver.state, .downloading(progress: 1))
    }

    func test_alreadyDownloaded_goesStraightToRestart() {
        driver.updateFound(version: "2.1.0", downloaded: true, userInitiated: false, reply: recordChoice)
        XCTAssertEqual(driver.state, .readyToRestart)
        driver.restart()
        XCTAssertEqual(choices, [.install])
    }

    // MARK: - Ignore

    func test_ignore_repliesSkip_andGoesIdle() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        driver.ignore()
        XCTAssertEqual(choices, [.skip])
        XCTAssertEqual(driver.state, .idle)
        XCTAssertNil(driver.version)
        XCTAssertFalse(driver.needsAttention)

        // Sparkle follows with a dismissal; nothing more is replied.
        driver.dismiss()
        XCTAssertEqual(choices, [.skip])
    }

    // MARK: - Exactly once

    func test_repeatedButtonPresses_replyOnce() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: true, reply: recordChoice)
        driver.update()
        driver.update()
        driver.ignore()
        XCTAssertEqual(choices, [.install])

        driver.readyToInstall(reply: recordChoice)
        driver.restart()
        driver.restart()
        XCTAssertEqual(choices, [.install, .install])
    }

    func test_actionsInTheWrongState_doNothing() {
        driver.update()
        driver.ignore()
        driver.restart()
        driver.retry()
        XCTAssertEqual(choices, [])
        XCTAssertEqual(driver.state, .idle)
    }

    func test_dismiss_dropsPendingReplies() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        driver.dismiss()
        XCTAssertEqual(driver.state, .idle)
        driver.update()
        XCTAssertEqual(choices, [])
    }

    // MARK: - Checks by hand

    func test_userInitiatedCheck_showsChecking() {
        driver.userInitiatedCheckStarted()
        XCTAssertEqual(driver.state, .checking)
    }

    func test_upToDate_acknowledgesAutomatically() {
        driver.upToDateDuration = 0.05
        driver.userInitiatedCheckStarted()
        driver.updateNotFound(acknowledgement: recordAcknowledgement)
        XCTAssertEqual(driver.state, .upToDate)

        let faded = expectation(description: "up to date fades")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { faded.fulfill() }
        wait(for: [faded], timeout: 1)

        XCTAssertEqual(acknowledgements, 1)
        XCTAssertEqual(driver.state, .idle)
    }

    func test_upToDate_dismissedEarly_acknowledgesOnce() {
        driver.upToDateDuration = 0.05
        driver.updateNotFound(acknowledgement: recordAcknowledgement)
        driver.acknowledge()
        XCTAssertEqual(acknowledgements, 1)

        let waited = expectation(description: "timer would have fired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { waited.fulfill() }
        wait(for: [waited], timeout: 1)
        XCTAssertEqual(acknowledgements, 1)
    }

    /// Sparkle's acknowledgements can dismiss the driver before they return. Calling one while
    /// still holding the stored closure was an exclusive-access violation, which crashed Pika
    /// when "Up to date" faded out.
    func test_acknowledgement_thatDismissesStraightAway_doesNotTrap() {
        driver.updateNotFound { [unowned self] in
            acknowledgements += 1
            driver.dismiss()
        }
        driver.acknowledge()
        XCTAssertEqual(acknowledgements, 1)
        XCTAssertEqual(driver.state, .idle)

        driver.updaterError(message: "Failed") { [unowned self] in driver.dismiss() }
        driver.acknowledge()
        XCTAssertEqual(driver.state, .idle)

        var retries = 0
        driver.installing(applicationTerminated: false) { [unowned self] in
            retries += 1
            driver.dismiss()
        }
        driver.restart()
        XCTAssertEqual(retries, 1)
    }

    // MARK: - Failures

    func test_failure_staysUntilDismissed() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        driver.update()
        driver.downloadStarted()
        driver.updaterError(message: "The network connection was lost.", acknowledgement: recordAcknowledgement)
        XCTAssertEqual(driver.state, .failed(message: "The network connection was lost."))
        XCTAssertEqual(acknowledgements, 0)

        driver.acknowledge()
        XCTAssertEqual(acknowledgements, 1)
        XCTAssertEqual(driver.state, .idle)
        driver.acknowledge()
        XCTAssertEqual(acknowledgements, 1)
    }

    func test_retry_acknowledges_thenChecksByHand() {
        var checks = 0
        driver.checkForUpdates = { checks += 1 }
        driver.updaterError(message: "Failed", acknowledgement: recordAcknowledgement)
        driver.retry()
        XCTAssertEqual(acknowledgements, 1)
        XCTAssertEqual(checks, 1)
        driver.retry()
        XCTAssertEqual(checks, 1)
    }

    // MARK: - Status bar flag

    func test_scheduledFind_flagsStatusBar_untilSeen() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        XCTAssertTrue(driver.needsAttention)
        driver.markSeen()
        XCTAssertFalse(driver.needsAttention)
    }

    func test_userInitiatedFind_doesNotFlagStatusBar() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: true, reply: recordChoice)
        XCTAssertFalse(driver.needsAttention)
    }

    func test_update_clearsFlag() {
        driver.updateFound(version: "2.1.0", downloaded: false, userInitiated: false, reply: recordChoice)
        driver.update()
        XCTAssertFalse(driver.needsAttention)
    }

    // MARK: - Installing

    func test_installing_withoutTermination_restartRetries() {
        var retries = 0
        driver.installing(applicationTerminated: false, retryTerminating: { retries += 1 })
        driver.restart()
        driver.restart()
        XCTAssertEqual(retries, 1)
    }
}
