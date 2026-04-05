import Foundation

enum EndpointNormalizer {
    static let defaultPort = 9600

    static func normalize(input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RemoteConnectionError.invalidAddress
        }

        let candidate: String
        if trimmed.contains("://") {
            candidate = trimmed
        } else {
            candidate = "http://\(trimmed)"
        }

        guard var components = URLComponents(string: candidate) else {
            throw RemoteConnectionError.invalidAddress
        }

        guard let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw RemoteConnectionError.invalidAddress
        }

        guard let host = components.host, !host.isEmpty else {
            throw RemoteConnectionError.invalidAddress
        }

        if components.port == nil {
            components.port = defaultPort
        }

        if components.path.isEmpty {
            components.path = "/"
        }

        guard let normalized = components.url else {
            throw RemoteConnectionError.invalidAddress
        }
        return normalized
    }

    static func endpoint(
        from input: String,
        displayName: String?,
        existingID: UUID? = nil,
        lastConnectedAt: Date? = nil
    ) throws -> RemoteEndpoint {
        let normalizedURL = try normalize(input: input)
        guard let host = normalizedURL.host, let scheme = normalizedURL.scheme else {
            throw RemoteConnectionError.invalidAddress
        }

        let name = displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? host

        return RemoteEndpoint(
            id: existingID ?? UUID(),
            displayName: name,
            host: host,
            port: normalizedURL.port ?? defaultPort,
            scheme: scheme,
            path: normalizedURL.path.isEmpty ? "/" : normalizedURL.path,
            lastConnectedAt: lastConnectedAt
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
