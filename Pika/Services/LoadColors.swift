import Cocoa
import Defaults

struct ColorName: Decodable {
    public var name: String
    public var hex: String
    public var color: NSColor {
        NSColor(hex: hex)
    }
}

struct ResponseData: Decodable {
    var colors: [ColorName]
}

/// A named colour list published by the color.pizza API (`/v1/lists/`).
struct ColorListInfo: Identifiable, Hashable {
    let key: String
    let title: String
    var id: String { key }
}

/// The key of the list bundled with the app as the offline fallback. It's downloaded as
/// part of the build so colour names always work without a network connection.
let defaultColorListKey = "default"

/// Loads the colour list bundled at build time — the `default` list, used as the offline
/// fallback until (and if) a network refresh caches a newer copy.
func loadColors() -> [ColorName]? {
    if let url = Bundle.main.url(forResource: "ColorNames", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(ResponseData.self, from: data)
            return jsonData.colors
        } catch {
            print("error:\(error)")
        }
    }
    return nil
}

/// Owns colour-name data sourced from the color.pizza API, with an offline fallback.
///
/// - The `default` list is downloaded during the build and bundled, so names always work
///   offline.
/// - On launch the currently-selected list is refreshed from the network and cached on disk.
/// - Settings and the splash let the user pick any list from `/v1/lists/`; if the chosen
///   list is no longer offered by the API, we fall back to `default`.
///
/// Reloads are broadcast via `.colorNamesUpdated` so the eyedroppers rebuild their lookup.
final class ColorNamesManager: ObservableObject {
    static let shared = ColorNamesManager()

    /// Lists offered by the API, for the picker UI. Empty until fetched from the network.
    @Published private(set) var availableLists: [ColorListInfo] = []

    private let session = URLSession.shared
    private let apiBase = "https://api.color.pizza/v1"

    private init() {}

    // MARK: - Loading names for the current list

    /// The colour names for the currently-selected list: the on-disk cache if present,
    /// otherwise the bundled `default` list.
    func currentColorNames() -> [ColorName] {
        let key = Defaults[.colorNameList]
        if let url = Self.cacheURL(for: key),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(ResponseData.self, from: data),
           !decoded.colors.isEmpty
        {
            return decoded.colors
        }
        return loadColors() ?? []
    }

    // MARK: - Launch update

    /// Refreshes the list catalogue and the selected list's colours from the network. Safe
    /// to call on every launch; any failure leaves the cached / bundled data untouched.
    func updateOnLaunch() {
        fetchLists { [weak self] infos, availableKeys in
            guard let self else { return }
            if !infos.isEmpty { self.availableLists = infos }

            // Fall back to `default` if the chosen list is no longer available.
            var key = Defaults[.colorNameList]
            if !availableKeys.isEmpty, !availableKeys.contains(key) {
                key = defaultColorListKey
                Defaults[.colorNameList] = key
                NotificationCenter.default.post(name: .colorNamesUpdated, object: nil)
            }
            self.refreshColors(for: key)
        }
    }

    /// Ensures the picker has a catalogue to show; used when Settings / the splash appear.
    func loadAvailableListsIfNeeded() {
        guard availableLists.isEmpty else { return }
        fetchLists { [weak self] infos, _ in
            if !infos.isEmpty { self?.availableLists = infos }
        }
    }

    /// Switches the active list: reflects the change immediately from cache / bundle, then
    /// fetches the latest colours for the newly-chosen list in the background.
    func selectList(_ key: String) {
        guard key != Defaults[.colorNameList] else { return }
        Defaults[.colorNameList] = key
        NotificationCenter.default.post(name: .colorNamesUpdated, object: nil)
        refreshColors(for: key)
    }

    private func refreshColors(for key: String) {
        fetchColors(for: key) { success in
            // Only signal a reload if this is still the active list when the fetch lands.
            guard success, Defaults[.colorNameList] == key else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .colorNamesUpdated, object: nil)
            }
        }
    }

    // MARK: - Networking

    private func fetchLists(completion: @escaping ([ColorListInfo], Set<String>) -> Void) {
        guard let url = URL(string: "\(apiBase)/lists/") else { completion([], []); return }
        session.dataTask(with: url) { data, _, _ in
            guard let data, let parsed = Self.parseLists(data) else {
                DispatchQueue.main.async { completion([], []) }
                return
            }
            DispatchQueue.main.async { completion(parsed.0, parsed.1) }
        }.resume()
    }

    private func fetchColors(for key: String, completion: @escaping (Bool) -> Void) {
        guard let escaped = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed),
              let url = URL(string: "\(apiBase)/?list=\(escaped)")
        else { completion(false); return }
        session.dataTask(with: url) { data, _, _ in
            guard let data,
                  let decoded = try? JSONDecoder().decode(ResponseData.self, from: data),
                  !decoded.colors.isEmpty,
                  let cacheURL = Self.cacheURL(for: key)
            else { completion(false); return }
            do {
                try data.write(to: cacheURL, options: .atomic)
                completion(true)
            } catch {
                completion(false)
            }
        }.resume()
    }

    // MARK: - Parsing

    private struct ListsResponse: Decodable {
        let available: [String]?
        let listDescriptions: [String: ListDescription]?
    }

    private struct ListDescription: Decodable {
        let title: String?
    }

    /// Parses `/v1/lists/` into `(orderedInfos, availableKeys)`, tolerating either the
    /// `available` array or the `listDescriptions` map being absent, and guaranteeing that
    /// `default` is always present and listed first.
    private static func parseLists(_ data: Data) -> ([ColorListInfo], Set<String>)? {
        guard let response = try? JSONDecoder().decode(ListsResponse.self, from: data) else { return nil }

        let descriptions = response.listDescriptions ?? [:]
        // Prefer the authoritative `available` ordering; otherwise use the described keys.
        var keys = response.available ?? Array(descriptions.keys).sorted()
        guard !keys.isEmpty else { return nil }

        // Ensure the bundled default is always offered and appears first.
        keys.removeAll { $0 == defaultColorListKey }
        keys.insert(defaultColorListKey, at: 0)

        let infos = keys.map { key -> ColorListInfo in
            // Keep `default` recognisable regardless of how the API labels it.
            let title = key == defaultColorListKey
                ? Self.prettify(key)
                : (descriptions[key]?.title ?? Self.prettify(key))
            return ColorListInfo(key: key, title: title)
        }
        return (infos, Set(keys))
    }

    /// A readable title for a list key the API didn't describe: `sanzoWadaI` -> `Sanzo Wada I`.
    private static func prettify(_ key: String) -> String {
        if key == defaultColorListKey { return "Default" }
        var result = ""
        for (index, character) in key.enumerated() {
            if index == 0 {
                result.append(Character(String(character).uppercased()))
            } else if character.isUppercase {
                result.append(" ")
                result.append(character)
            } else {
                result.append(character)
            }
        }
        return result
    }

    // MARK: - Cache location

    private static func cacheDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        let dir = base.appendingPathComponent("Pika/ColorLists", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func cacheURL(for key: String) -> URL? {
        // Guard against odd list keys resolving to unexpected paths.
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory()?.appendingPathComponent("\(safeKey).json")
    }
}

private extension CharacterSet {
    /// Query-value-safe set: the query set minus the sub-delims that break `?list=` values.
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=?+/")
        return set
    }()
}
