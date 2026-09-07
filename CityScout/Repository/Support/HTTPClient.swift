//
//  HTTPClient.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

protocol HTTPClient {
    func get(url: URL) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    static func makeConfiguredSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15
        return URLSession(configuration: configuration)
    }

    func get(url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidServerResponse
        }
        return (data, httpResponse)
    }
}
