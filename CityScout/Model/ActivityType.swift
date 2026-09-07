//
//  ActivityType.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//


import Foundation

enum ActivityType: String, CaseIterable, Identifiable, Sendable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skiing: return "Skiing"
        case .surfing: return "Surfing"
        case .outdoorSightseeing: return "Outdoor sightseeing"
        case .indoorSightseeing: return "Indoor sightseeing"
        }
    }
}
