import Foundation

enum ConnectionState: Equatable {
    case idle
    case connecting
    case loaded
    case failed(RemoteConnectionError)
    case permissionDenied
}

enum RemoteConnectionError: Error, Equatable {
    case invalidAddress
    case unreachable
    case permissionDenied
    case insecureTransportBlocked
    case invalidResponse
    case requestFailed(String)

    var title: String {
        switch self {
        case .invalidAddress:
            return "Invalid Address"
        case .unreachable:
            return "Server Unreachable"
        case .permissionDenied:
            return "Local Network Permission Required"
        case .insecureTransportBlocked:
            return "HTTP Blocked"
        case .invalidResponse:
            return "Unexpected Response"
        case .requestFailed:
            return "Request Failed"
        }
    }

    var recoveryMessage: String {
        switch self {
        case .invalidAddress:
            return "Enter an IPv4 address, IPv6 address, host:port, or full http:// URL."
        case .unreachable:
            return "Make sure VACS is running, remote control is enabled, and you are using the correct IP address and port."
        case .permissionDenied:
            return "Allow local network access for VACS Remote in Settings when connecting on LAN, then try again."
        case .insecureTransportBlocked:
            return "The device blocked the HTTP connection. Verify App Transport Security settings and use a trusted LAN or VPN path to the desktop server."
        case .invalidResponse:
            return "The server responded unexpectedly. Verify that the address points to a VACS desktop remote-control server."
        case .requestFailed(let message):
            return message
        }
    }

    static func map(_ error: Error) -> RemoteConnectionError {
        if let error = error as? RemoteConnectionError {
            return error
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorAppTransportSecurityRequiresSecureConnection:
                return .insecureTransportBlocked
            case NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet:
                return .unreachable
            default:
                break
            }
        }

        if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(EACCES) {
            return .permissionDenied
        }

        let loweredDescription = nsError.localizedDescription.lowercased()
        if loweredDescription.contains("local network") || loweredDescription.contains("permission") {
            return .permissionDenied
        }

        return .requestFailed(nsError.localizedDescription)
    }
}
