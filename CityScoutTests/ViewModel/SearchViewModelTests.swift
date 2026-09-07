//
//  SearchViewModelTests.swift
//  CityScoutTests
//
//  Created by Ankur Kothawade on 06/09/26.
//

import XCTest
@testable import CityScout

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testSearchViewModelInitialStateIsIdle() async {
        let stub = StubCitySearchRepository()
        let sut = SearchViewModel { query in
            try await stub.searchCities(query: query)
        }

        let state = sut.state
        XCTAssertEqual(state, .idle)
    }

    func testDebouncedQueryPublishesResults() async throws {
        let expected = [City(name: "Tokyo", country: "Japan", latitude: 35.67, longitude: 139.65)]
        let repo = CitySearchRepositorySpy(mode: .success(expected))
        let sut = SearchViewModel { query in
            try await repo.searchCities(query: query)
        }

        sut.query = "Tokyo"
        try await Task.sleep(nanoseconds: 700_000_000)

        let state = sut.state
        XCTAssertEqual(state, .results(expected))
        let queries = await repo.queries()
        XCTAssertEqual(queries, ["Tokyo"])
    }

    func testWhitespaceQueryResetsToIdleAndSkipsSearch() async throws {
        let repo = CitySearchRepositorySpy(mode: .success([]))
        let sut = SearchViewModel { query in
            try await repo.searchCities(query: query)
        }

        sut.query = "   "
        try await Task.sleep(nanoseconds: 700_000_000)

        let state = sut.state
        XCTAssertEqual(state, .idle)
        let queries = await repo.queries()
        XCTAssertTrue(queries.isEmpty)
    }

    func testFailedSearchPublishesErrorMessage() async throws {
        let repo = CitySearchRepositorySpy(mode: .failure(AppError.networkUnavailable))
        let sut = SearchViewModel { query in
            try await repo.searchCities(query: query)
        }

        sut.query = "Paris"
        try await Task.sleep(nanoseconds: 700_000_000)

        let state = sut.state
        XCTAssertEqual(state, .failed(AppError.networkUnavailable.message))
        let queries = await repo.queries()
        XCTAssertEqual(queries, ["Paris"])
    }
}
