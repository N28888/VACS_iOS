import Foundation

final class ConnectionRepository {
    static let defaultStorageKey = "recentRemoteEndpoints"

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = ConnectionRepository.defaultStorageKey
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func loadRecentEndpoints() -> [RemoteEndpoint] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try decoder.decode([RemoteEndpoint].self, from: data)
                .sorted(by: endpointSort)
        } catch {
            return []
        }
    }

    func save(_ endpoints: [RemoteEndpoint]) {
        let trimmed = Array(endpoints.sorted(by: endpointSort).prefix(10))
        guard let data = try? encoder.encode(trimmed) else {
            return
        }
        userDefaults.set(data, forKey: storageKey)
    }

    func upsert(_ endpoint: RemoteEndpoint) {
        var endpoints = loadRecentEndpoints()
        endpoints.removeAll { existing in
            existing.id == endpoint.id || (existing.host == endpoint.host && existing.port == endpoint.port)
        }
        endpoints.insert(endpoint, at: 0)
        save(endpoints)
    }

    func upsertConnected(_ endpoint: RemoteEndpoint, date: Date = Date()) {
        upsert(endpoint.touched(at: date))
    }

    func delete(_ endpoint: RemoteEndpoint) {
        let remaining = loadRecentEndpoints().filter { $0.id != endpoint.id }
        save(remaining)
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }

    private func endpointSort(lhs: RemoteEndpoint, rhs: RemoteEndpoint) -> Bool {
        switch (lhs.lastConnectedAt, rhs.lastConnectedAt) {
        case let (.some(left), .some(right)):
            return left > right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
}
