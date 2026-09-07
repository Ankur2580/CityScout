//
//  DestinationViewModelTests.swift
//  CityScoutTests
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
import XCTest
@testable import CityScout

@MainActor
final class DestinationViewModelTests: XCTestCase {
    func testFetchRankingPublishesSuccess() async throws {
        let city = City(name: "Lisbon", country: "Portugal", latitude: 38.72, longitude: -9.13)
        let repo = WeatherRepositorySpy(mode: .success(makeWeek(min: 16, max: 24, rain: 0.2, snow: 0, wind: 10)))
        let sut = DestinationViewModel(
            city: city,
            fetchForecast: { city in
                try await repo.fetchForecast(for: city)
            }
        )

        sut.fetchRanking()
        try await waitUntilDone(sut)

        let state = sut.state
        guard case let .success(activities) = state else {
            XCTFail("Expected success state")
            return
        }
        XCTAssertFalse(activities.isEmpty)
    }

    func testFetchRankingPublishesFailure() async throws {
        let city = City(name: "Oslo", country: "Norway", latitude: 59.91, longitude: 10.75)
        let repo = WeatherRepositorySpy(mode: .failure(AppError.forecastUnavailable))
        let sut = DestinationViewModel(
            city: city,
            fetchForecast: { city in
                try await repo.fetchForecast(for: city)
            }
        )

        sut.fetchRanking()
        try await waitUntilDone(sut)

        let state = sut.state
        XCTAssertEqual(state, .failed(AppError.forecastUnavailable.message))
    }

    private func waitUntilDone(_ sut: DestinationViewModel) async throws {
        for _ in 0..<120 {
            let state = sut.state
            if case .loading = state {
                try await Task.sleep(nanoseconds: 20_000_000)
                continue
            }
            return
        }
    }

    private func makeWeek(min: Double, max: Double, rain: Double, snow: Double, wind: Double) -> [DailyWeather] {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return (0..<7).map { index in
            DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: index, to: start) ?? start,
                minTempC: min,
                maxTempC: max,
                precipitationMM: rain,
                snowfallCM: snow,
                maxWindKph: wind
            )
        }
    }
}
