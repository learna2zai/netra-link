/// APIRequest.swift
///
/// Types for describing API requests and converting them into `URLRequest` instances.
///
/// This file defines the `HTTPMethod` enum, the `APIRequest` protocol that models the
/// components of an HTTP request, and a helper function to convert an `APIRequest`
/// and base URL into a concrete `URLRequest` for execution.

import Foundation

/// Standard HTTP methods supported by the networking layer.
///
/// The raw value of each case is the uppercase string expected by `URLRequest.httpMethod`.
public enum HTTPMethod: String, Sendable {
    /// The HTTP GET method.
    case GET
    /// The HTTP POST method.
    case POST
    /// The HTTP PUT method.
    case PUT
    /// The HTTP DELETE method.
    case DELETE
}

/// A description of an API request used to construct a `URLRequest`.
///
/// Conforming types provide path, headers, method, body, query items, and timeout needed
/// to build a `URLRequest` relative to a base URL.
public protocol APIRequest: Sendable {
    /// The relative path component to append to the base URL (e.g. "/v1/users").
    var path: String { get }
    /// Additional HTTP headers to include with the request.
    var headers: [String: String] { get }
    /// The HTTP method to use for the request.
    var method: HTTPMethod { get }
    /// Optional HTTP body data for the request (typically JSON).
    var body: Data? { get }
    /// Optional URL query items to attach to the request URL.
    var queryItems: [URLQueryItem]? { get }
    /// The timeout interval, in seconds, for the request.
    var timeout: TimeInterval { get }
}

/// Converts an `APIRequest` and base URL string into a `URLRequest`.
///
/// This function appends `request.path` to the provided `baseUrl`, applies any `queryItems`,
/// sets the HTTP method, body, timeout, and headers, and ensures a JSON `Content-Type` header
/// is present.
///
/// - Parameters:
///   - baseUrl: The base URL string used to construct the absolute request URL.
///   - request: The `APIRequest` describing the endpoint and request configuration.
/// - Returns: A `URLRequest` ready to be executed.
/// - Throws: `URLError(.badURL)` if the base URL or composed URL is invalid.
func convertToRequest(_ baseUrl: String, _ request: APIRequest) throws -> URLRequest {
    guard let baseURL = URL(string: baseUrl),
          var components = URLComponents(url: baseURL.appendingPathComponent(request.path),
                                         resolvingAgainstBaseURL: true) else {
        throw URLError(.badURL)
    }
    components.queryItems = request.queryItems
    guard let url = components.url else {
        throw URLError(.badURL)
    }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body
    urlRequest.timeoutInterval = request.timeout
    request.headers.forEach { key, value in
        urlRequest.setValue(value, forHTTPHeaderField: key)
    }
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    return urlRequest
}
