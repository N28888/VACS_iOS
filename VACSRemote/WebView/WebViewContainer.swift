import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @ObservedObject var store: WebViewStore
    let onLoadStarted: () -> Void
    let onLoadFinished: () -> Void
    let onLoadFailed: (RemoteConnectionError) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.addUserScript(disableZoomScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.accessibilityIdentifier = "remote-web-view"
        store.webView = webView
        context.coordinator.load(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        store.webView = webView
        if webView.url != url {
            context.coordinator.load(url, in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: WebViewContainer

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        func load(_ url: URL, in webView: WKWebView) {
            parent.onLoadStarted()
            webView.load(URLRequest(url: url))
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onLoadFinished()
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            parent.onLoadFailed(RemoteConnectionError.map(error))
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            parent.onLoadFailed(RemoteConnectionError.map(error))
        }
    }

    private var disableZoomScript: WKUserScript {
        let source = """
        (function() {
          var content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
          var meta = document.querySelector('meta[name=\"viewport\"]');
          if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
          }
          meta.setAttribute('content', content);
        })();
        """

        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
}
