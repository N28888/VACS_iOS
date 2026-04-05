import SwiftUI

struct ContentView: View {
    @ObservedObject var connectionListViewModel: ConnectionListViewModel
    @ObservedObject var remoteWebViewModel: RemoteWebViewModel

    @AppStorage("hasAcceptedRemoteSecurityNotice")
    private var hasAcceptedRemoteSecurityNotice = false

    @State private var activeSheet: ConnectionFormSheet?
    @State private var pendingConnection: RemoteEndpoint?
    @State private var activeError: RemoteConnectionError?

    var body: some View {
        NavigationStack {
            ConnectionListView(
                endpoints: connectionListViewModel.recentEndpoints,
                connectionState: remoteWebViewModel.connectionState,
                onConnect: attemptConnection,
                onAdd: { activeSheet = .create },
                onEdit: { endpoint in activeSheet = .edit(endpoint) },
                onDelete: { endpoint in
                    connectionListViewModel.delete(endpoint)
                }
            )
            .navigationTitle("VACS Remote")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .create
                    } label: {
                        Label("Add Server", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            ConnectionFormView(
                mode: sheet,
                onSave: { displayName, address, existing in
                    try connectionListViewModel.saveEndpoint(
                        displayName: displayName,
                        addressInput: address,
                        editing: existing
                    )
                }
            )
        }
        .fullScreenCover(item: $remoteWebViewModel.currentEndpoint, onDismiss: {
            remoteWebViewModel.disconnect()
            connectionListViewModel.reload()
        }) { endpoint in
            RemoteSessionView(endpoint: endpoint)
        }
        .alert(
            "Trusted Network Only",
            isPresented: Binding(
                get: { pendingConnection != nil },
                set: { newValue in
                    if !newValue {
                        pendingConnection = nil
                    }
                }
            ),
            presenting: pendingConnection
        ) { endpoint in
            Button("Cancel", role: .cancel) {
                pendingConnection = nil
            }
            Button("Continue") {
                hasAcceptedRemoteSecurityNotice = true
                pendingConnection = nil
                connect(endpoint)
            }
        } message: { endpoint in
            Text(
                "\(endpoint.displayName) uses the VACS desktop remote server over plain HTTP with no authentication. Only connect over a trusted local network or VPN."
            )
        }
        .alert("Connection Failed", isPresented: Binding(
            get: { activeError != nil },
            set: { newValue in
                if !newValue {
                    activeError = nil
                    remoteWebViewModel.clearFailureState()
                }
            }
        )) {
            Button("OK", role: .cancel) {
                activeError = nil
                remoteWebViewModel.clearFailureState()
            }
        } message: {
            Text(activeError?.recoveryMessage ?? "Unable to connect to the VACS desktop server.")
        }
        .onChange(of: remoteWebViewModel.connectionState) { _, newState in
            switch newState {
            case .failed(let error):
                activeError = error
            case .permissionDenied:
                activeError = .permissionDenied
            default:
                break
            }
        }
    }

    private func attemptConnection(_ endpoint: RemoteEndpoint) {
        if hasAcceptedRemoteSecurityNotice {
            connect(endpoint)
        } else {
            pendingConnection = endpoint
        }
    }

    private func connect(_ endpoint: RemoteEndpoint) {
        Task {
            await remoteWebViewModel.connect(to: endpoint)
            connectionListViewModel.reload()
        }
    }
}

enum ConnectionFormSheet: Identifiable, Equatable {
    case create
    case edit(RemoteEndpoint)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let endpoint):
            return endpoint.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .create:
            return "Add Server"
        case .edit:
            return "Edit Server"
        }
    }

    var endpoint: RemoteEndpoint? {
        switch self {
        case .create:
            return nil
        case .edit(let endpoint):
            return endpoint
        }
    }
}
