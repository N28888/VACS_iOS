import XCTest
@testable import VACSRemote

final class ConnectionRepositoryTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var repository: ConnectionRepository!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: #function)
        userDefaults.removePersistentDomain(forName: #function)
        repository = ConnectionRepository(userDefaults: userDefaults, storageKey: "endpoints")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: #function)
        userDefaults = nil
        repository = nil
        super.tearDown()
    }

    func testUpsertDeduplicatesByHostAndPort() {
        let first = RemoteEndpoint(displayName: "One", host: "192.168.1.10", port: 9600)
        let second = RemoteEndpoint(displayName: "Two", host: "192.168.1.10", port: 9600)

        repository.upsert(first)
        repository.upsert(second)

        let endpoints = repository.loadRecentEndpoints()
        XCTAssertEqual(endpoints.count, 1)
        XCTAssertEqual(endpoints.first?.displayName, "Two")
    }

    func testSaveCapsAtTenRecentEndpoints() {
        let endpoints = (0..<12).map { index in
            RemoteEndpoint(
                displayName: "Server \(index)",
                host: "192.168.1.\(index)",
                port: 9600,
                lastConnectedAt: Date().addingTimeInterval(TimeInterval(index))
            )
        }

        repository.save(endpoints)

        XCTAssertEqual(repository.loadRecentEndpoints().count, 10)
    }

    func testDeleteRemovesEndpoint() {
        let endpoint = RemoteEndpoint(displayName: "Home", host: "192.168.1.20", port: 9600)
        repository.upsert(endpoint)

        repository.delete(endpoint)

        XCTAssertTrue(repository.loadRecentEndpoints().isEmpty)
    }
}
