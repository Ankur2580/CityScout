//
//  StubCitySearchRepository.swift
//  CityScoutTests
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
@testable import CityScout

struct StubCitySearchRepository {
    func searchCities(query: String) async throws -> [City] {
        []
    }
}

actor CitySearchRepositorySpy {
    enum Mode {
        case success([City])
        case failure(Error)
    }

    private let mode: Mode
    private var recordedQueries: [String] = []

    init(mode: Mode) {
        self.mode = mode
    }

    func searchCities(query: String) async throws -> [City] {
        recordedQueries.append(query)
        switch mode {
        case let .success(cities):
            return cities
        case let .failure(error):
            throw error
        }
    }

    func queries() -> [String] {
        recordedQueries
    }
}

actor WeatherRepositorySpy {
    enum Mode {
        case success([DailyWeather])
        case failure(Error)
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchForecast(for city: City) async throws -> [DailyWeather] {
        switch mode {
        case let .success(week):
            return week
        case let .failure(error):
            throw error
        }
    }
}
