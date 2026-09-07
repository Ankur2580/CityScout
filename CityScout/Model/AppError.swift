//
//  AppError.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

enum AppError: Error, Equatable, Sendable {
    case emptyQuery
    case noCityResults
    case noForecastData
    case invalidGeocodingRequest
    case citySearchRedirected(statusCode: Int)
    case citySearchBadRequest
    case citySearchUnauthorized
    case citySearchForbidden
    case citySearchNotFound
    case citySearchRequestTimeout
    case citySearchRateLimited
    case citySearchServerUnavailable(statusCode: Int)
    case citySearchFailed(statusCode: Int)
    case citySearchUnavailable
    case invalidForecastRequest
    case forecastFailed(statusCode: Int)
    case forecastUnavailable
    case invalidServerResponse
    case networkUnavailable

    var message: String {
        switch self {
        case .emptyQuery: return "Please type a city name."
        case .noCityResults: return "No matching cities found."
        case .noForecastData: return "Could not load weather forecast data."
        case .invalidGeocodingRequest: return "Could not create geocoding request."
        case let .citySearchRedirected(statusCode): return "City search was redirected unexpectedly (status \(statusCode))."
        case .citySearchBadRequest: return "City search request was invalid."
        case .citySearchUnauthorized: return "City search is unauthorized."
        case .citySearchForbidden: return "City search is forbidden."
        case .citySearchNotFound: return "City search endpoint not found."
        case .citySearchRequestTimeout: return "City search request timed out."
        case .citySearchRateLimited: return "City search rate limit exceeded. Try again shortly."
        case let .citySearchServerUnavailable(statusCode): return "City search service is unavailable (status \(statusCode))."
        case let .citySearchFailed(statusCode): return "City search failed with status \(statusCode)."
        case .citySearchUnavailable: return "Failed to search cities. Check network and try again."
        case .invalidForecastRequest: return "Could not create forecast request."
        case let .forecastFailed(statusCode): return "Forecast request failed with status \(statusCode)."
        case .forecastUnavailable: return "Failed to load weather forecast. Check network and try again."
        case .invalidServerResponse: return "Invalid server response."
        case .networkUnavailable: return "Network unavailable"
        }
    }
}
