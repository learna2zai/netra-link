/// NetraLink.swift
///
/// A lightweight abstraction over URLSession for sending HTTP requests defined by `APIRequest`
/// and decoding JSON responses.
///
/// This file defines the `NetraLink` protocol and a default implementation `NetraLinkImpl` that
/// composes a `URLRequest` from an `APIRequest` and a base URL, performs a network request using
/// `URLSession`, validates the HTTP response, and decodes the returned data into the requested
/// `Decodable` type.
import Foundation

/// A networking abstraction that sends an `APIRequest` and decodes the response.
///
/// Conforming types are expected to build a `URLRequest` from the provided `APIRequest`, perform
/// the request, validate the response, and decode the returned data into the generic `Decodable`
/// type specified by the caller.
public protocol INetraLink: Sendable {
    /// Sends an `APIRequest` and decodes the response body into the specified `Decodable` type.
    ///
    /// - Parameter request: The `APIRequest` describing path, method, headers, and body.
    /// - Returns: A value of type `T` decoded from the response body.
    /// - Throws: An error if the request fails, the response is invalid, or decoding fails.
    func send<T: Decodable>(request: APIRequest) async throws -> T
}

/// Default implementation of `NetraLink` backed by `URLSession`.
///
/// This implementation composes a `URLRequest` from a base URL and `APIRequest`, uses
/// `URLSession.data(for:)` to perform requests, requires an HTTP 200 status code, and decodes
/// JSON responses using `JSONDecoder`.
public struct NetraLink: INetraLink {
    
    /// The base URL used to build absolute request URLs from `APIRequest` paths.
    private let baseUrl: String
    
    /// The `URLSession` used to perform network requests.
    private var session: URLSession
    
    /// Creates a new instance.
    ///
    /// - Parameters:
    ///   - baseUrl: The base URL string used to compose absolute URLs for requests.
    ///   - session: The `URLSession` to use. Defaults to `URLSession.shared`.
    public init(baseUrl: String, session: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.session = session
    }
    
    /// Sends an `APIRequest` and decodes the response body into the specified `Decodable` type.
    ///
    /// This method composes a `URLRequest` from the provided `APIRequest` and the configured base
    /// URL, performs the request using the configured `URLSession`, validates that the response is
    /// an `HTTPURLResponse` with a 200 status code, and attempts to decode the response data into
    /// `T` using `JSONDecoder`.
    ///
    /// - Parameter request: The `APIRequest` describing the endpoint, method, headers, and body.
    /// - Returns: A value of type `T` decoded from the response body.
    /// - Throws: `URLError(.badServerResponse)` if the response isn't HTTP or the status code isn't
    ///           200, or a decoding error if the data cannot be decoded into `T`.
    public func send<T: Decodable>(request: APIRequest) async throws -> T {
        let urlRequest = try convertToRequest(baseUrl, request)
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

