import SwiftUI

struct ConnectionListView: View {
    let endpoints: [RemoteEndpoint]
    let connectionState: ConnectionState
    let onConnect: (RemoteEndpoint) -> Void
    let onAdd: () -> Void
    let onEdit: (RemoteEndpoint) -> Void
    let onDelete: (RemoteEndpoint) -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("UI matches the official VACS remote frontend.", systemImage: "ipad.and.iphone")
                    Label("Audio stays on the desktop app.", systemImage: "speaker.slash")
                    Label("Only use this on trusted local networks.", systemImage: "exclamationmark.shield")
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            } header: {
                Text("Remote Control")
            }

            Section {
                Button(action: onAdd) {
                    Label("Add VACS Desktop", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("add-server-inline-button")
            }

            Section {
                if endpoints.isEmpty {
                    ContentUnavailableView(
                        "No Saved Servers",
                        systemImage: "desktopcomputer.trianglebadge.exclamationmark",
                        description: Text("Add a VACS desktop address such as 192.168.1.10 or http://192.168.1.10:9600")
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 12)
                } else {
                    ForEach(endpoints) { endpoint in
                        ConnectionRow(
                            endpoint: endpoint,
                            isConnecting: connectionState == .connecting
                        ) {
                            onConnect(endpoint)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                onDelete(endpoint)
                            }
                            Button("Edit") {
                                onEdit(endpoint)
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button("Connect") {
                                onConnect(endpoint)
                            }
                            Button("Edit") {
                                onEdit(endpoint)
                            }
                            Button("Delete", role: .destructive) {
                                onDelete(endpoint)
                            }
                        }
                    }
                }
            } header: {
                Text("Recent Servers")
            } footer: {
                footerView
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("connection-list-view")
    }

    @ViewBuilder
    private var footerView: some View {
        switch connectionState {
        case .connecting:
            HStack(spacing: 8) {
                ProgressView()
                Text("Checking the remote server before opening the session.")
            }
        default:
            Text("The app stores up to 10 recent servers and opens the remote UI from the desktop app directly.")
        }
    }
}

private struct ConnectionRow: View {
    let endpoint: RemoteEndpoint
    let isConnecting: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(endpoint.displayName)
                    .font(.headline)
                Text(endpoint.url.absoluteString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if let lastConnectedAt = endpoint.lastConnectedAt {
                    Text("Last connected \(lastConnectedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not connected yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)

            Button("Connect", action: onConnect)
                .buttonStyle(.borderedProminent)
                .disabled(isConnecting)
                .accessibilityIdentifier("connection-row-connect-button")
        }
        .padding(.vertical, 4)
    }
}
