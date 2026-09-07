//
//  ActivityScore.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation

struct ActivityScore: Equatable, Identifiable, Sendable {
    var id: String { activity.rawValue }
    let activity: ActivityType
    let score: Int
    let reason: String
}
