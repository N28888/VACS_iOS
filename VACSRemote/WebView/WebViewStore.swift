import Foundation
import WebKit

@MainActor
final class WebViewStore: ObservableObject {
    weak var webView: WKWebView?

    func reload() {
        webView?.reload()
    }
}
