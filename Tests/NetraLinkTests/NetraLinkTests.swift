import Foundation
import Testing
@testable import NetraLink

struct MockAPIRequest: APIRequest {
    var path: String = ""
    var method: HTTPMethod = .GET
    var headers: [String: String] = [:]
    var body: Data? = nil
    var queryItems: [URLQueryItem]?
    var timeout: TimeInterval = 10
}

@Suite("NetraLink Tests", .serialized)
struct NetraLinkTests {
    
    let baseUrl = "http://example.com"
    
    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
    
    private func resetMockURLProtocol() {
        MockURLProtocol.data = nil
        MockURLProtocol.error = nil
        MockURLProtocol.response = nil
    }
    
    @Test("Verify the NetraLink instance default behaviour")
    func verifyNetraLink() async throws {
        
        let netraLink = NetraLink(baseUrl: "")
        let request = MockAPIRequest()
        let result = try await #require(throws: URLError.self) {
            let _: String = try await netraLink.send(request: request)
        }
        #expect(result.code == URLError.badURL)
    }
    
    @Test("Verify the Netralink intasnce success response")
    func verifyNetraLinkSuccess() async throws {
        resetMockURLProtocol()
        MockURLProtocol.data = try JSONEncoder().encode(["message":"Hello"])
        MockURLProtocol.response = HTTPURLResponse(url: URL(string: baseUrl)!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: [:])
        let mockSession = makeMockSession()
        let netraLink = NetraLink(baseUrl: baseUrl, session: mockSession)
        let request = MockAPIRequest(path: "/get", headers: ["x-api-key":"eeweqqw"])
        let response: [String: String] = try await netraLink.send(request: request)
        #expect(!response.isEmpty)
    }
    
    @Test("Verify the Netralink for failuer response")
    func verifyNetraLinkFailure() async throws {
        resetMockURLProtocol()
        MockURLProtocol.response = HTTPURLResponse(url: URL(string: baseUrl)!,
                                                   statusCode: 404,
                                                   httpVersion: nil,
                                                   headerFields: [:])
        let mockSession = makeMockSession()
        let netraLink = NetraLink(baseUrl: baseUrl, session: mockSession)
        let request = MockAPIRequest(path: "/get")
        let result = try await #require(throws: URLError.self) {
            let _: String = try await netraLink.send(request: request)
        }
        #expect(result.code == .badServerResponse)
    }
    
    @Test("Verify the NetraLink for invalid error")
    func verifyNetraLinkInvalidQueryItems() async throws {
        resetMockURLProtocol()
        MockURLProtocol.error = URLError(.unknown)
        let netraLink = NetraLink(baseUrl: baseUrl, session: makeMockSession())
        let request = MockAPIRequest(path: "/get")
        
        let result = try await #require(throws: URLError.self) {
            let _: String = try await netraLink.send(request: request)
        }
        #expect(result.code == .unknown)
    }
}
