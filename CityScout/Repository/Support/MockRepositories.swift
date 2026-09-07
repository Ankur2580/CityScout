//
//  MockCitySearchRepository.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

struct MockCitySearchRepository {
    func searchCities(query: String) async throws -> [City] {
        let all = [
            City(name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503),
            City(name: "Zurich", country: "Switzerland", latitude: 47.3769, longitude: 8.5417),
            City(name: "San Diego", country: "United States", latitude: 32.7157, longitude: -117.1611),
            City(name: "Reykjavik", country: "Iceland", latitude: 64.1466, longitude: -21.9426)
        ]

        return all.filter { city in
            city.name.localizedCaseInsensitiveContains(query)
        }
    }
}

struct MockWeatherRepository {
    func fetch7DayForecast(latitude: Double, longitude: Double) async throws -> [DailyWeather] {
        let now = Date()
        let calendar = Calendar.current

        let template: (Double, Double, Double, Double, Double)
        if latitude > 45 {
            template = (-6, 1, 2, 10, 16)
        } else if latitude > 30 {
            template = (16, 24, 0.5, 0, 9)
        } else {
            template = (11, 19, 4, 0, 20)
        }

        return (0..<7).map { day in
            DailyWeather(
                date: calendar.date(byAdding: .day, value: day, to: now) ?? now,
                minTempC: template.0,
                maxTempC: template.1,
                precipitationMM: template.2,
                snowfallCM: template.3,
                maxWindKph: template.4
            )
        }
    }
}
