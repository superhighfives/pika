import Foundation

extension LatestAppStoreVersion {
    var shouldUpdate: Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        let systemVersion = ProcessInfo().operatingSystemVersion
        let versionString = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"

        let isRemoteVersionHigherThanLocal = currentVersion.compare(version, options: .numeric) == .orderedAscending
        let isSystemVersionAllowed = versionString.compare(minimumOsVersion, options: .numeric) == .orderedDescending

        return isRemoteVersionHigherThanLocal && isSystemVersionAllowed
    }
}
