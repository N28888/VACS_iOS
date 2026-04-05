import Foundation

struct RemoteEndpoint: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var host: String
    var port: Int
    var scheme: String
    var path: String
    var lastConnectedAt: Date?

    init(
        id: UUID = UUID(),
        displayName: String,
        host: String,
        port: Int,
        scheme: String = "http",
        path: String = "/",
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.host = host
        self.port = port
        self.scheme = scheme
        self.path = path.isEmpty ? "/" : path
        self.lastConnectedAt = lastConnectedAt
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = path.isEmpty ? "/" : path
        return components.url!
    }

    var addressLabel: String {
        let printableHost = host.contains(":") ? "[\(host)]" : host
        return "\(printableHost):\(port)"
    }

    func touched(at date: Date = Date()) -> RemoteEndpoint {
        var copy = self
        copy.lastConnectedAt = date
        return copy
    }
}
