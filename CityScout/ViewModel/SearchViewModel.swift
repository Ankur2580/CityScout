//
//  SearchViewModel.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case searching
        case results([City])
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published var query: String = ""

    private let searchCities: @Sendable (String) async throws -> [City]
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(searchCities: @escaping @Sendable (String) async throws -> [City]) {
        self.searchCities = searchCities
        setupBindings()
    }

    func search() {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            reset()
            return
        }
        performSearch(for: cleaned)
    }

    func onDisappear() {
        searchTask?.cancel()
        searchTask = nil
    }

    func reset() {
        searchTask?.cancel()
        searchTask = nil
        state = .idle
    }

    private func setupBindings() {
        $query
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] cleanedQuery in
                guard let self else { return }
                if cleanedQuery.isEmpty {
                    self.reset()
                } else {
                    self.performSearch(for: cleanedQuery)
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch(for searchQuery: String) {
        searchTask?.cancel()
        state = .searching

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let cities = try await self.searchCities(searchQuery)
                guard !cities.isEmpty else {
                    throw AppError.noCityResults
                }
                try Task.checkCancellation()
                self.state = .results(cities)
            } catch is CancellationError {
                return
            } catch let error as AppError {
                self.state = .failed(error.message)
            } catch {
                self.state = .failed("Something went wrong while searching cities.")
            }
        }
    }
}
