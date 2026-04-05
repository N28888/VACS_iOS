import Foundation

@MainActor
final class RemoteWebViewModel: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .idle
    @Published var currentEndpoint: RemoteEndpoint?

    private let repository: ConnectionRepository
    private let preflight: (URL) async throws -> Void

    init(
        repository: ConnectionRepository,
        preflight: @escaping (URL) async throws -> Void = { url in
            try await ReachabilityPreflight.check(url: url)
        }
    ) {
        self.repository = repository
        self.preflight = preflight
    }

    func connect(to endpoint: RemoteEndpoint) async {
        connectionState = .connecting

        do {
            try await preflight(endpoint.url)
            let connected = endpoint.touched()
            repository.upsert(connected)
            currentEndpoint = connected
            connectionState = .loaded
        } catch {
            let mapped = RemoteConnectionError.map(error)
            currentEndpoint = nil
            if mapped == .permissionDenied {
                connectionState = .permissionDenied
            } else {
                connectionState = .failed(mapped)
            }
        }
    }

    func clearFailureState() {
        if case .failed = connectionState {
            connectionState = .idle
        } else if connectionState == .permissionDenied {
            connectionState = .idle
        }
    }

    func disconnect() {
        currentEndpoint = nil
        connectionState = .idle
    }
}
