//
//  OpenMeteoCitySearchRepository.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//


import Foundation

struct OpenMeteoCitySearchRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func searchCities(query: String) async throws -> [City] {
        let queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = OpenMeteoEndpoint.geocodingSearch.makeURL(queryItems: queryItems) else {
            throw AppError.invalidGeocodingRequest
        }

        do {
            let (data, response) = try await httpClient.get(url: url)
            guard 200..<300 ~= response.statusCode else {
                throw mapCitySearchError(for: response.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(CitySearchResponse.self, from: data)
            let cities = (decoded.results ?? []).map { cityResult in
                City(
                    name: cityResult.name,
                    country: cityResult.country ?? cityResult.countryCode ?? "Unknown",
                    latitude: cityResult.latitude,
                    longitude: cityResult.longitude
                )
            }
            return cities
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.citySearchUnavailable
        }
    }

    private func mapCitySearchError(for statusCode: Int) -> AppError {
        switch statusCode {
        case 300..<400:
            .citySearchRedirected(statusCode: statusCode)
        case 400:
            .citySearchBadRequest
        case 401:
            .citySearchUnauthorized
        case 403:
            .citySearchForbidden
        case 404:
            .citySearchNotFound
        case 408:
            .citySearchRequestTimeout
        case 429:
            .citySearchRateLimited
        case 500, 502, 503, 504:
            .citySearchServerUnavailable(statusCode: statusCode)
        default:
            .citySearchFailed(statusCode: statusCode)
        }
    }
}
