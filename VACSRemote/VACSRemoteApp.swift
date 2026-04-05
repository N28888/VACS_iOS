import SwiftUI

@main
struct VACSRemoteApp: App {
    private static let acceptedNoticeKey = "hasAcceptedRemoteSecurityNotice"

    @StateObject private var connectionListViewModel: ConnectionListViewModel
    @StateObject private var remoteWebViewModel: RemoteWebViewModel

    init() {
        if ProcessInfo.processInfo.arguments.contains("UITestingResetStorage") {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: ConnectionRepository.defaultStorageKey)
            defaults.removeObject(forKey: Self.acceptedNoticeKey)
        }

        let repository = ConnectionRepository()
        _connectionListViewModel = StateObject(
            wrappedValue: ConnectionListViewModel(repository: repository)
        )
        _remoteWebViewModel = StateObject(
            wrappedValue: RemoteWebViewModel(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                connectionListViewModel: connectionListViewModel,
                remoteWebViewModel: remoteWebViewModel
            )
        }
    }
}
