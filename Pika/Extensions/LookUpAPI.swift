import Foundation

struct LookUpResponse: Decodable {
    let results: [LookUpResult]

    struct LookUpResult: Decodable {
        let version: String
        let minimumOsVersion: String
        let trackViewUrl: URL
    }
}

struct LatestAppStoreVersion {
    let version: String
    let minimumOsVersion: String
    let upgradeURL: URL
}

final class LookUpAPI {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    init(session: URLSession = .shared, jsonDecoder: JSONDecoder = .init()) {
        self.session = session
        self.jsonDecoder = jsonDecoder
    }

    func getLatestAvailableVersion(for appID: String) async throws -> LatestAppStoreVersion? {
        let url = URL(string: "https://itunes.apple.com/lookup?appId=\(appID)")!
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let response = try jsonDecoder.decode(LookUpResponse.self, from: data)

        print(response)

        return response.results.first.map {
            .init(version: $0.version,
                  minimumOsVersion: $0.minimumOsVersion,
                  upgradeURL: $0.trackViewUrl)
        }
    }
}
