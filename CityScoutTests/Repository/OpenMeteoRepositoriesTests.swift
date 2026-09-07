//
//  OpenMeteoRepositoriesTests.swift
//  CityScoutTests
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
import XCTest
@testable import CityScout

@MainActor
final class OpenMeteoRepositoriesTests: XCTestCase {
    func testCitySearchMapsCountryCodeFallback() async throws {
        let payload = """
        {
          "results": [
            {
              "name": "Seattle",
              "country_code": "US",
              "latitude": 47.6062,
              "longitude": -122.3321
            }
          ]
        }
        """

        let client = HTTPClientStub(outcomes: [
            .success(data: Data(payload.utf8), statusCode: 200)
        ])
        let sut = OpenMeteoCitySearchRepository(httpClient: client)

        let cities = try await sut.searchCities(query: "Seattle")
        let firstName = cities.first?.name
        let firstCountry = cities.first?.country

        XCTAssertEqual(cities.count, 1)
        XCTAssertEqual(firstName, "Seattle")
        XCTAssertEqual(firstCountry, "US")
    }

    func testForecastMapsDailyWeather() async throws {
        let payload = """
        {
          "daily": {
            "time": ["2026-09-07", "2026-09-08"],
            "temperature_2m_max": [24.0, 25.0],
            "temperature_2m_min": [16.0, 17.0],
            "precipitation_sum": [1.2, 0.0],
            "snowfall_sum": [0.0, 0.0],
            "wind_speed_10m_max": [10.0, 12.0]
          }
        }
        """

        let client = HTTPClientStub(outcomes: [
            .success(data: Data(payload.utf8), statusCode: 200)
        ])
        let sut = OpenMeteoWeatherRepository(httpClient: client)

        let week = try await sut.fetch7DayForecast(latitude: 51.5072, longitude: -0.1276)
        let firstMinTemp = week[0].minTempC
        let firstMaxTemp = week[0].maxTempC

        XCTAssertEqual(week.count, 2)
        XCTAssertEqual(firstMinTemp, 16.0)
        XCTAssertEqual(firstMaxTemp, 24.0)
    }

    func testForecastReturnsNoForecastDataWhenDatesCannotBeParsed() async throws {
        let payload = """
        {
          "daily": {
            "time": ["bad-date"],
            "temperature_2m_max": [24.0],
            "temperature_2m_min": [16.0],
            "precipitation_sum": [1.2],
            "snowfall_sum": [0.0],
            "wind_speed_10m_max": [10.0]
          }
        }
        """

        let client = HTTPClientStub(outcomes: [
            .success(data: Data(payload.utf8), statusCode: 200)
        ])
        let sut = OpenMeteoWeatherRepository(httpClient: client)

        do {
            _ = try await sut.fetch7DayForecast(latitude: 1, longitude: 1)
            XCTFail("Expected noForecastData error")
        } catch let error as AppError {
            XCTAssertEqual(error, .noForecastData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testForecastDoesNotRetryAfterTransientNetworkError() async throws {
        let payload = """
        {
          "daily": {
            "time": ["2026-09-07"],
            "temperature_2m_max": [24.0],
            "temperature_2m_min": [16.0],
            "precipitation_sum": [1.2],
            "snowfall_sum": [0.0],
            "wind_speed_10m_max": [10.0]
          }
        }
        """

        let client = HTTPClientStub(outcomes: [
            .failure(URLError(.timedOut)),
            .success(data: Data(payload.utf8), statusCode: 200)
        ])
        let sut = OpenMeteoWeatherRepository(httpClient: client)

        do {
            _ = try await sut.fetch7DayForecast(latitude: 1, longitude: 1)
            XCTFail("Expected forecastUnavailable error")
        } catch let error as AppError {
            let calls = await client.callCount
            XCTAssertEqual(error, .forecastUnavailable)
            XCTAssertEqual(calls, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testForecastDoesNotRetryAfterServerErrorStatus() async throws {
        let payload = """
        {
          "daily": {
            "time": ["2026-09-07"],
            "temperature_2m_max": [24.0],
            "temperature_2m_min": [16.0],
            "precipitation_sum": [1.2],
            "snowfall_sum": [0.0],
            "wind_speed_10m_max": [10.0]
          }
        }
        """

        let client = HTTPClientStub(outcomes: [
            .success(data: Data("{}".utf8), statusCode: 503),
            .success(data: Data(payload.utf8), statusCode: 200)
        ])
        let sut = OpenMeteoWeatherRepository(httpClient: client)

        do {
            _ = try await sut.fetch7DayForecast(latitude: 1, longitude: 1)
            XCTFail("Expected forecastFailed error")
        } catch let error as AppError {
            let calls = await client.callCount
            XCTAssertEqual(error, .forecastFailed(statusCode: 503))
            XCTAssertEqual(calls, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private actor HTTPClientStub: HTTPClient {
    enum Outcome {
        case success(data: Data, statusCode: Int)
        case failure(Error)
    }

    private var outcomes: [Outcome]
    private(set) var callCount = 0

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func get(url: URL) async throws -> (Data, HTTPURLResponse) {
        callCount += 1
        guard !outcomes.isEmpty else {
            throw URLError(.badServerResponse)
        }
        let outcome = outcomes.removeFirst()

        switch outcome {
        case let .success(data, statusCode):
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            guard let response else {
                throw URLError(.badServerResponse)
            }
            return (data, response)
        case let .failure(error):
            throw error
        }
    }
}
