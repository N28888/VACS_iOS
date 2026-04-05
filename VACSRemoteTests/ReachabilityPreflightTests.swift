import Foundation
import XCTest
@testable import VACSRemote

final class ReachabilityPreflightTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.requestHandler = nil
    }

    func testCheckSucceedsForHTTPResponse() async throws {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await ReachabilityPreflight.check(
            url: URL(string: "http://192.168.1.10:9600")!,
            session: makeSession()
        )
    }

    func testCheckSkipsURLSessionPreflightForPlainHTTP() async throws {
        URLProtocolStub.requestHandler = { _ in
            XCTFail("HTTP URLs should not run URLSession preflight")
            throw URLError(.badURL)
        }

        try await ReachabilityPreflight.check(
            url: URL(string: "http://100.100.1.2:9600")!,
            session: makeSession()
        )
    }

    func testCheckMapsTimeoutToUnreachable() async {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            try await ReachabilityPreflight.check(
                url: URL(string: "http://192.168.1.10:9600")!,
                session: makeSession()
            )
            XCTFail("Expected timeout error")
        } catch let error as RemoteConnectionError {
            XCTAssertEqual(error, .unreachable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCheckMapsPermissionFailure() async {
        URLProtocolStub.requestHandler = { _ in
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES))
        }

        do {
            try await ReachabilityPreflight.check(
                url: URL(string: "http://192.168.1.10:9600")!,
                session: makeSession()
            )
            XCTFail("Expected permission error")
        } catch let error as RemoteConnectionError {
            XCTAssertEqual(error, .permissionDenied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}

final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
