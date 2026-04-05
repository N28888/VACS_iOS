import XCTest
@testable import VACSRemote

final class EndpointNormalizerTests: XCTestCase {
    func testNormalizesBareIPv4Address() throws {
        let url = try EndpointNormalizer.normalize(input: "192.168.1.10")
        XCTAssertEqual(url.absoluteString, "http://192.168.1.10:9600/")
    }

    func testNormalizesExplicitPort() throws {
        let url = try EndpointNormalizer.normalize(input: "192.168.1.10:9700")
        XCTAssertEqual(url.absoluteString, "http://192.168.1.10:9700/")
    }

    func testPreservesFullURL() throws {
        let url = try EndpointNormalizer.normalize(input: "http://192.168.1.10:9800/remote")
        XCTAssertEqual(url.absoluteString, "http://192.168.1.10:9800/remote")
    }

    func testRejectsMalformedInput() {
        XCTAssertThrowsError(try EndpointNormalizer.normalize(input: ""))
        XCTAssertThrowsError(try EndpointNormalizer.normalize(input: "http://"))
        XCTAssertThrowsError(try EndpointNormalizer.normalize(input: "ftp://192.168.1.10"))
    }
}
