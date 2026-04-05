import SwiftUI

struct RemoteSessionView: View {
    let endpoint: RemoteEndpoint

    @StateObject private var webViewStore = WebViewStore()
    @State private var isLoading = true
    @State private var navigationError: RemoteConnectionError?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(
                    red: 121 / 255,
                    green: 128 / 255,
                    blue: 141 / 255
                )
                    .ignoresSafeArea()

                WebViewContainer(
                    url: endpoint.url,
                    store: webViewStore,
                    onLoadStarted: {
                        isLoading = true
                        navigationError = nil
                    },
                    onLoadFinished: {
                        isLoading = false
                        navigationError = nil
                    },
                    onLoadFailed: { error in
                        isLoading = false
                        navigationError = error
                    }
                )
                .ignoresSafeArea(.container, edges: .bottom)

                if isLoading {
                    loadingOverlay
                } else if let navigationError {
                    failureOverlay(for: navigationError)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("remote-session-view")
            .accessibilityValue(sessionStateAccessibilityValue)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading remote interface…")
                .font(.headline)
            Text(endpoint.url.absoluteString)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier("remote-loading-overlay")
    }

    private func failureOverlay(for error: RemoteConnectionError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
            Text(error.title)
                .font(.headline)
            Text(error.recoveryMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                isLoading = true
                navigationError = nil
                webViewStore.reload()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(24)
        .accessibilityIdentifier("remote-failure-overlay")
    }

    private var sessionStateAccessibilityValue: String {
        if isLoading {
            return "loading"
        }

        if navigationError != nil {
            return "failed"
        }

        return "loaded"
    }
}
