import XCTest
@testable import VACSRemote

final class RemoteWebViewModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var repository: ConnectionRepository!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: #function)
        userDefaults.removePersistentDomain(forName: #function)
        repository = ConnectionRepository(userDefaults: userDefaults, storageKey: "remoteWebView")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: #function)
        userDefaults = nil
        repository = nil
        super.tearDown()
    }

    @MainActor
    func testConnectMarksLoadedAndStoresEndpoint() async {
        let endpoint = RemoteEndpoint(displayName: "Home", host: "192.168.1.10", port: 9600)
        let viewModel = RemoteWebViewModel(repository: repository) { _ in }

        await viewModel.connect(to: endpoint)

        XCTAssertEqual(viewModel.connectionState, .loaded)
        XCTAssertEqual(viewModel.currentEndpoint?.host, endpoint.host)
        XCTAssertEqual(repository.loadRecentEndpoints().count, 1)
    }

    @MainActor
    func testConnectMapsPermissionDeniedState() async {
        let endpoint = RemoteEndpoint(displayName: "Home", host: "192.168.1.10", port: 9600)
        let viewModel = RemoteWebViewModel(repository: repository) { _ in
            throw RemoteConnectionError.permissionDenied
        }

        await viewModel.connect(to: endpoint)

        XCTAssertEqual(viewModel.connectionState, .permissionDenied)
        XCTAssertNil(viewModel.currentEndpoint)
    }

    @MainActor
    func testConnectMapsGenericFailure() async {
        let endpoint = RemoteEndpoint(displayName: "Home", host: "192.168.1.10", port: 9600)
        let viewModel = RemoteWebViewModel(repository: repository) { _ in
            throw URLError(.timedOut)
        }

        await viewModel.connect(to: endpoint)

        XCTAssertEqual(viewModel.connectionState, .failed(.unreachable))
        XCTAssertNil(viewModel.currentEndpoint)
    }
}
