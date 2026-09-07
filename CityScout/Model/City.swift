//
//  City.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

struct City: Equatable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double

    init(name: String, country: String, latitude: Double, longitude: Double) {
        self.id = "\(name)-\(country)-\(latitude)-\(longitude)"
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct CitySearchResponse: Decodable {
    let results: [CitySearchResult]?
}

struct CitySearchResult: Decodable {
    let name: String
    let country: String?
    let countryCode: String?
    let latitude: Double
    let longitude: Double
}
