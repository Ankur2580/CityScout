//
//  AppSetupBuilder.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

enum AppSetupBuilder {
    private static let liveSession = URLSessionHTTPClient.makeConfiguredSession()
    private static let liveClient = URLSessionHTTPClient(session: liveSession)
    private static let liveCityRepo = OpenMeteoCitySearchRepository(httpClient: liveClient)
    private static let liveWeatherRepo = OpenMeteoWeatherRepository(httpClient: liveClient)

    private static let previewCityRepo = MockCitySearchRepository()
    private static let previewWeatherRepo = MockWeatherRepository()

    static func makeSearchViewModel() -> SearchViewModel {
        return SearchViewModel { query in
            try await liveCityRepo.searchCities(query: query)
        }
    }

    static func makePreviewSearchViewModel() -> SearchViewModel {
        return SearchViewModel { query in
            try await previewCityRepo.searchCities(query: query)
        }
    }

    static func makeDestinationViewModel(for city: City) -> DestinationViewModel {
        DestinationViewModel(
            city: city,
            fetchForecast: { city in
                try await liveWeatherRepo.fetch7DayForecast(latitude: city.latitude, longitude: city.longitude)
            }
        )
    }

    static func makePreviewDestinationViewModel(for city: City) -> DestinationViewModel {
        DestinationViewModel(
            city: city,
            fetchForecast: { city in
                try await previewWeatherRepo.fetch7DayForecast(latitude: city.latitude, longitude: city.longitude)
            }
        )
    }
}
