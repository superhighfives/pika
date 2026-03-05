import Cocoa
import Defaults
import Security

/// Keeps paletteText in sync between local Defaults and iCloud KVS.
/// Degrades gracefully to local-only when the KVS entitlement is absent (e.g. dev builds).
class PaletteSyncManager: ObservableObject {
    /// Whether iCloud KVS is available (entitlement present and store initialized).
    var iCloudAvailable: Bool { store != nil }

    /// Set when iCloud reports a quota violation.
    @Published var quotaExceeded = false

    private var store: NSUbiquitousKeyValueStore?
    private let key = Defaults.Keys.paletteText.name

    /// Token to break the cloud→Defaults→cloud feedback loop.
    /// Set before writing a cloud value into Defaults; consumed by the Defaults observer
    /// so it knows to skip pushing that same value back to iCloud.
    /// Only set when the cloud value actually differs from Defaults — otherwise KVO
    /// won't fire and the token would go stale, suppressing a future legitimate edit.
    private var lastCloudAppliedValue: String?

    private static var hasKVSEntitlement: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        let value = SecTaskCopyValueForEntitlement(
            task, "com.apple.developer.ubiquity-kvstore-identifier" as CFString, nil
        )
        return value != nil
    }

    init() {
        if Self.hasKVSEntitlement {
            let kvStore = NSUbiquitousKeyValueStore.default
            store = kvStore

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cloudDidChange(_:)),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: kvStore
            )

            kvStore.synchronize()

            if let cloudValue = kvStore.string(forKey: key), Defaults[.paletteText].isEmpty {
                lastCloudAppliedValue = cloudValue
                Defaults[.paletteText] = cloudValue
            }
        }

        Defaults.observe(.paletteText) { [weak self] change in
            guard let self = self else { return }
            if change.newValue == self.lastCloudAppliedValue {
                self.lastCloudAppliedValue = nil
                return
            }
            self.store?.set(change.newValue, forKey: self.key)
        }.tieToLifetime(of: self)
    }

    /// Handles iCloud KVS external change notifications (server sync, initial sync, account change).
    @objc private func cloudDidChange(_ notification: Notification) {
        guard let store = store,
              let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        else { return }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange,
             NSUbiquitousKeyValueStoreAccountChange:
            if let cloudValue = store.string(forKey: key) {
                if cloudValue != Defaults[.paletteText] {
                    lastCloudAppliedValue = cloudValue
                }
                Defaults[.paletteText] = cloudValue
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            quotaExceeded = true
            NSLog("PaletteSyncManager: iCloud KVS quota exceeded")
        default:
            break
        }
    }
}
