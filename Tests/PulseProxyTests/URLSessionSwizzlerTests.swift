// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

import Pulse
@testable import PulseProxy
import XCTest

final class URLSessionSwizzlerTests: XCTestCase {
    private static let recorder = CompletedTaskRecorder()

    override class func setUp() {
        super.setUp()
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try! LoggerStore(storeURL: storeURL, options: [.create, .inMemory])
        let logger = NetworkLogger(store: store) { configuration in
            configuration.willHandleEvent = { event in
                URLSessionSwizzlerTests.recorder.record(event)
                return event
            }
        }
        NetworkLogger.enableProxy(logger: logger)
    }

    /// The system buffers a plain text body for content sniffing and delivers it again when the task finishes.
    func testTextPlainBodyDeliveredOnCompletionIsRecordedOnce() throws {
        let body = Data("Invalid phone number".utf8)

        let recordedBody = try loadRecordedBody(body, contentType: "text/plain; charset=utf-8", chunkSize: body.count)

        XCTAssertEqual(recordedBody, body)
    }

    func testTextPlainBodyReceivedInChunksIsRecordedOnce() throws {
        let body = Data(String(repeating: "a", count: 3000).utf8)

        let recordedBody = try loadRecordedBody(body, contentType: "text/plain", chunkSize: 100)

        XCTAssertEqual(recordedBody, body)
    }

    func testTextPlainBodySmallerThanSniffingWindowIsRecordedOnce() throws {
        let body = Data("short plain text body".utf8)

        let recordedBody = try loadRecordedBody(body, contentType: "text/plain", chunkSize: 5)

        XCTAssertEqual(recordedBody, body)
    }

    func testJSONBodyReceivedInChunksIsRecordedOnce() throws {
        let body = Data(#"{"message":"\#(String(repeating: "a", count: 3000))"}"#.utf8)

        let recordedBody = try loadRecordedBody(body, contentType: "application/json", chunkSize: 100)

        XCTAssertEqual(recordedBody, body)
    }

    /// Sends a request through a stubbed session and returns the response body the logger stored for it.
    private func loadRecordedBody(_ body: Data, contentType: String, chunkSize: Int) throws -> Data? {
        let url = try XCTUnwrap(URL(string: "https://example.com/\(UUID().uuidString)"))
        StubURLProtocol.responses[url] = StubURLProtocol.Response(body: body, contentType: contentType, chunkSize: chunkSize)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)

        let completed = expectation(description: "Request completed")
        session.dataTask(with: url) { _, _, _ in completed.fulfill() }.resume()
        wait(for: [completed], timeout: 5)

        let recorded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in Self.recorder.body(for: url) != nil }, object: nil)
        wait(for: [recorded], timeout: 5)
        return Self.recorder.body(for: url)
    }
}

private final class CompletedTaskRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var bodies: [URL: Data] = [:]

    func record(_ event: LoggerStore.Event) {
        guard case let .networkTaskCompleted(completed) = event, let url = completed.originalRequest.url else {
            return
        }
        lock.lock()
        bodies[url] = completed.responseBody ?? Data()
        lock.unlock()
    }

    func body(for url: URL) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return bodies[url]
    }
}

private final class StubURLProtocol: URLProtocol {
    struct Response {
        let body: Data
        let contentType: String
        let chunkSize: Int
    }

    nonisolated(unsafe) static var responses: [URL: Response] = [:]

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let response = Self.responses[url] else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let headers = ["Content-Type": response.contentType, "Content-Length": String(response.body.count)]
        let httpResponse = HTTPURLResponse(url: url, statusCode: 400, httpVersion: "HTTP/1.1", headerFields: headers)!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        var offset = 0
        while offset < response.body.count {
            let end = min(offset + response.chunkSize, response.body.count)
            client?.urlProtocol(self, didLoad: response.body.subdata(in: offset ..< end))
            offset = end
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
