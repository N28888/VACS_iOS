import Foundation

@MainActor
final class ConnectionListViewModel: ObservableObject {
    @Published private(set) var recentEndpoints: [RemoteEndpoint] = []

    private let repository: ConnectionRepository

    init(repository: ConnectionRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        recentEndpoints = repository.loadRecentEndpoints()
    }

    func saveEndpoint(
        displayName: String,
        addressInput: String,
        editing existing: RemoteEndpoint?
    ) throws {
        let endpoint = try EndpointNormalizer.endpoint(
            from: addressInput,
            displayName: displayName,
            existingID: existing?.id,
            lastConnectedAt: existing?.lastConnectedAt
        )
        repository.upsert(endpoint)
        reload()
    }

    func delete(_ endpoint: RemoteEndpoint) {
        repository.delete(endpoint)
        reload()
    }
}
