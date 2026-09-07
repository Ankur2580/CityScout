//
//  DailyWeather.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

struct DailyWeather: Equatable, Sendable {
    let date: Date
    let minTempC: Double
    let maxTempC: Double
    let precipitationMM: Double
    let snowfallCM: Double
    let maxWindKph: Double

    var averageTempC: Double {
        (minTempC + maxTempC) / 2
    }
}

struct ForecastResponse: Decodable {
    let daily: ForecastDaily
}

struct ForecastDaily: Decodable {
    let time: [String]
    let temperature2MMax: [Double]
    let temperature2MMin: [Double]
    let precipitationSum: [Double]
    let snowfallSum: [Double]
    let windSpeed10MMax: [Double]
}
