import XCTest
import Network

final class VACSRemoteUITests: XCTestCase {
    private var server: MockRemoteServer?
    private let realServerAddress = "127.0.0.1:9600"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        server?.stop()
        server = nil
    }

    @MainActor
    func testConnectsToRemoteServerAndLoadsRemoteUI() throws {
        let server = try MockRemoteServer()
        self.server = server

        let app = XCUIApplication()
        app.launchArguments = ["UITestingResetStorage"]
        app.launch()

        app.buttons["add-server-inline-button"].tap()

        let displayNameField = app.textFields["connection-form-display-name-field"]
        XCTAssertTrue(displayNameField.waitForExistence(timeout: 2))
        displayNameField.tap()
        displayNameField.typeText("Test Desktop")

        let addressField = app.textFields["connection-form-address-field"]
        addressField.tap()
        addressField.typeText("127.0.0.1:\(server.port)")

        app.buttons["connection-form-save-button"].tap()

        let connectButton = app.buttons["connection-row-connect-button"].firstMatch
        XCTAssertTrue(connectButton.waitForExistence(timeout: 2))
        connectButton.tap()

        let securityAlert = app.alerts["Trusted Network Only"]
        XCTAssertTrue(securityAlert.waitForExistence(timeout: 2))
        securityAlert.buttons["Continue"].tap()

        let remoteSessionView = app.otherElements["remote-session-view"]
        XCTAssertTrue(remoteSessionView.waitForExistence(timeout: 5))
        let loadedPredicate = NSPredicate(format: "value == %@", "loaded")
        expectation(for: loadedPredicate, evaluatedWith: remoteSessionView)
        waitForExpectations(timeout: 10)
        XCTAssertFalse(app.otherElements["remote-loading-overlay"].exists)
        XCTAssertTrue(app.webViews["remote-web-view"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testConnectsToRealVACSRemoteServer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestingResetStorage"]
        app.launch()

        app.buttons["add-server-inline-button"].tap()

        let displayNameField = app.textFields["connection-form-display-name-field"]
        XCTAssertTrue(displayNameField.waitForExistence(timeout: 2))
        displayNameField.tap()
        displayNameField.typeText("Real VACS Desktop")

        let addressField = app.textFields["connection-form-address-field"]
        addressField.tap()
        addressField.typeText(realServerAddress)

        app.buttons["connection-form-save-button"].tap()

        let connectButton = app.buttons["connection-row-connect-button"].firstMatch
        XCTAssertTrue(connectButton.waitForExistence(timeout: 2))
        connectButton.tap()

        let securityAlert = app.alerts["Trusted Network Only"]
        XCTAssertTrue(securityAlert.waitForExistence(timeout: 2))
        securityAlert.buttons["Continue"].tap()

        let remoteSessionView = app.otherElements["remote-session-view"]
        XCTAssertTrue(remoteSessionView.waitForExistence(timeout: 5))
        let loadedPredicate = NSPredicate(format: "value == %@", "loaded")
        expectation(for: loadedPredicate, evaluatedWith: remoteSessionView)
        waitForExpectations(timeout: 10)

        XCTAssertFalse(app.alerts["Connection Failed"].exists)
        XCTAssertFalse(app.otherElements["remote-failure-overlay"].exists)
        XCTAssertFalse(app.otherElements["remote-loading-overlay"].exists)
        XCTAssertTrue(app.webViews["remote-web-view"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testShowsConnectionFailureForUnreachableServer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestingResetStorage"]
        app.launch()

        app.buttons["add-server-inline-button"].tap()

        let displayNameField = app.textFields["connection-form-display-name-field"]
        XCTAssertTrue(displayNameField.waitForExistence(timeout: 2))
        displayNameField.tap()
        displayNameField.typeText("Broken Desktop")

        let addressField = app.textFields["connection-form-address-field"]
        addressField.tap()
        addressField.typeText("127.0.0.1:65534")

        app.buttons["connection-form-save-button"].tap()

        let connectButton = app.buttons["connection-row-connect-button"].firstMatch
        XCTAssertTrue(connectButton.waitForExistence(timeout: 2))
        connectButton.tap()

        let securityAlert = app.alerts["Trusted Network Only"]
        XCTAssertTrue(securityAlert.waitForExistence(timeout: 2))
        securityAlert.buttons["Continue"].tap()

        let failureAlert = app.alerts["Connection Failed"]
        XCTAssertTrue(failureAlert.waitForExistence(timeout: 8))
    }
}

private final class MockRemoteServer: @unchecked Sendable {
    let port: UInt16

    private let listener: NWListener
    private let queue: DispatchQueue

    init() throws {
        let queue = DispatchQueue(label: "MockRemoteServer")
        self.queue = queue
        listener = try NWListener(using: .tcp, on: .any)

        let readySemaphore = DispatchSemaphore(value: 0)
        let startState = ListenerStartState()

        listener.stateUpdateHandler = { [weak listener] state in
            switch state {
            case .ready:
                startState.resolvedPort = listener?.port?.rawValue
                readySemaphore.signal()
            case .failed(let error):
                startState.startError = error
                readySemaphore.signal()
            default:
                break
            }
        }

        listener.newConnectionHandler = { connection in
            Self.handle(connection, on: queue)
        }
        listener.start(queue: queue)

        readySemaphore.wait()

        if let startError = startState.startError {
            throw startError
        }

        guard let resolvedPort = startState.resolvedPort else {
            throw ServerError.failedToBind
        }

        port = resolvedPort
    }

    func stop() {
        listener.cancel()
    }

    private static func handle(_ connection: NWConnection, on queue: DispatchQueue) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { _, _, _, _ in
            let body = """
            <!doctype html>
            <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Mock VACS Remote</title>
            </head>
            <body>
              <main>
                <h1>Mock VACS Remote</h1>
                <p>Remote page loaded successfully.</p>
              </main>
            </body>
            </html>
            """
            let response = """
            HTTP/1.1 200 OK\r
            Content-Type: text/html; charset=utf-8\r
            Content-Length: \(body.utf8.count)\r
            Connection: close\r
            \r
            \(body)
            """

            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private enum ServerError: Error {
        case failedToBind
    }

    private final class ListenerStartState: @unchecked Sendable {
        var resolvedPort: UInt16?
        var startError: Error?
    }
}
