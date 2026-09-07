//
//  OpenMeteoWeatherRepository.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
import os

struct OpenMeteoWeatherRepository {
    private let httpClient: HTTPClient
    private let logger = Logger(subsystem: "CityScout", category: "OpenMeteoWeatherRepository")

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch7DayForecast(latitude: Double, longitude: Double) async throws -> [DailyWeather] {
        let queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = OpenMeteoEndpoint.forecast.makeURL(queryItems: queryItems) else {
            throw AppError.invalidForecastRequest
        }

        do {
            let (data, response) = try await httpClient.get(url: url)
            guard 200..<300 ~= response.statusCode else {
                throw AppError.forecastFailed(statusCode: response.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(ForecastResponse.self, from: data)
            return try mapToDailyWeather(decoded.daily)
        } catch let decodingError as DecodingError {
            logger.error("Forecast decoding failed: \(String(describing: decodingError), privacy: .public)")
            throw AppError.forecastUnavailable
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.forecastUnavailable
        }
    }

    private func mapToDailyWeather(_ daily: ForecastDaily) throws -> [DailyWeather] {
        let count = [
            daily.time.count,
            daily.temperature2MMax.count,
            daily.temperature2MMin.count,
            daily.precipitationSum.count,
            daily.snowfallSum.count,
            daily.windSpeed10MMax.count
        ].min() ?? 0

        guard count > 0 else {
            throw AppError.noForecastData
        }

        let fullDateFormatter = DateFormatter()
        fullDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        fullDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fullDateFormatter.dateFormat = "yyyy-MM-dd"

        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withFullDate]

        let isoDateTimeFormatter = ISO8601DateFormatter()
        isoDateTimeFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackIsoDateTimeFormatter = ISO8601DateFormatter()
        fallbackIsoDateTimeFormatter.formatOptions = [.withInternetDateTime]

        let mapped: [DailyWeather] = (0..<count).compactMap { (index: Int) -> DailyWeather? in
            guard let date = parseDate(
                from: daily.time[index],
                fullDateFormatter: fullDateFormatter,
                isoDateFormatter: isoDateFormatter,
                isoDateTimeFormatter: isoDateTimeFormatter,
                fallbackIsoDateTimeFormatter: fallbackIsoDateTimeFormatter
            ) else {
                logger.error("Failed to parse forecast date string: \(daily.time[index], privacy: .public)")
                return nil
            }
            return DailyWeather(
                date: date,
                minTempC: daily.temperature2MMin[index],
                maxTempC: daily.temperature2MMax[index],
                precipitationMM: daily.precipitationSum[index],
                snowfallCM: daily.snowfallSum[index],
                maxWindKph: daily.windSpeed10MMax[index]
            )
        }

        guard !mapped.isEmpty else {
            throw AppError.noForecastData
        }
        return mapped
    }

    private func parseDate(
        from value: String,
        fullDateFormatter: DateFormatter,
        isoDateFormatter: ISO8601DateFormatter,
        isoDateTimeFormatter: ISO8601DateFormatter,
        fallbackIsoDateTimeFormatter: ISO8601DateFormatter
    ) -> Date? {
        if let date = fullDateFormatter.date(from: value) {
            return date
        }
        if let date = isoDateFormatter.date(from: value) {
            return date
        }
        if let date = isoDateTimeFormatter.date(from: value) {
            return date
        }
        return fallbackIsoDateTimeFormatter.date(from: value)
    }
}
