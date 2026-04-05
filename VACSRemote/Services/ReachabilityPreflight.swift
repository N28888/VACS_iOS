import Foundation

enum ReachabilityPreflight {
    static func check(url: URL, session: URLSession = .shared) async throws {
        if url.scheme?.lowercased() == "http" {
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await session.data(for: request)
            guard response is HTTPURLResponse else {
                throw RemoteConnectionError.invalidResponse
            }
        } catch {
            throw RemoteConnectionError.map(error)
        }
    }
}
