//
//  DestinationViewModel.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
import Combine

@MainActor
final class DestinationViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case success([ActivityScore])
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    let city: City

    private let fetchForecast: @Sendable (City) async throws -> [DailyWeather]
    private let ranker: ActivityRanker
    private var fetchTask: Task<Void, Never>?

    init(
        city: City,
        fetchForecast: @escaping @Sendable (City) async throws -> [DailyWeather],
        ranker: ActivityRanker? = nil
    ) {
        self.city = city
        self.fetchForecast = fetchForecast
        self.ranker = ranker ?? ActivityRanker()
    }

    func fetchRanking() {
        fetchTask?.cancel()
        state = .loading

        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let week = try await self.fetchForecast(self.city)
                guard !week.isEmpty else {
                    throw AppError.noForecastData
                }
                let ranking = try self.ranker.rank(week: week)
                try Task.checkCancellation()
                self.state = .success(ranking)
            } catch is CancellationError {
                return
            } catch let error as AppError {
                self.state = .failed(error.message)
            } catch {
                self.state = .failed("Could not load weather forecast data.")
            }
        }
    }

    func retry() {
        fetchRanking()
    }

    func onDisappear() {
        fetchTask?.cancel()
        fetchTask = nil
    }
}
