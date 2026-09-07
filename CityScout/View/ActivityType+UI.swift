//
//  ActivityType+UI.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import SwiftUI

extension ActivityType {
    var symbolName: String {
        switch self {
        case .skiing: return "snowflake"
        case .surfing: return "water.waves"
        case .outdoorSightseeing: return "binoculars.fill"
        case .indoorSightseeing: return "building.2.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .skiing: return AppColors.activitySkiing
        case .surfing: return AppColors.activitySurfing
        case .outdoorSightseeing: return AppColors.activityOutdoor
        case .indoorSightseeing: return AppColors.activityIndoor
        }
    }
}
