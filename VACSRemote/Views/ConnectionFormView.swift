import SwiftUI

struct ConnectionFormView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: ConnectionFormSheet
    let onSave: (String, String, RemoteEndpoint?) throws -> Void

    @State private var displayName: String
    @State private var addressInput: String
    @State private var validationMessage: String?

    init(
        mode: ConnectionFormSheet,
        onSave: @escaping (String, String, RemoteEndpoint?) throws -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        _displayName = State(initialValue: mode.endpoint?.displayName ?? "")
        _addressInput = State(initialValue: mode.endpoint?.url.absoluteString ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Display name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("connection-form-display-name-field")

                    TextField("192.168.1.10 or http://192.168.1.10:9600", text: $addressInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("connection-form-address-field")

                    Text("The default port is 9600. Full http:// URLs are preserved.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .accessibilityIdentifier("connection-form-save-button")
                }
            }
        }
    }

    private func save() {
        do {
            try onSave(displayName, addressInput, mode.endpoint)
            dismiss()
        } catch let error as RemoteConnectionError {
            validationMessage = error.recoveryMessage
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}
