import Foundation
import XCTest
@testable import CityScout

final class ActivityRankerTests: XCTestCase {
    func testRankThrowsWhenWeekIsEmpty() {
        let sut = ActivityRanker()

        XCTAssertThrowsError(try sut.rank(week: [])) { error in
            guard let appError = error as? AppError else {
                XCTFail("Expected AppError")
                return
            }
            XCTAssertEqual(appError, .noForecastData)
        }
    }

    func testRankReturnsFourActivitiesSortedDescending() throws {
        let sut = ActivityRanker()
        let week = makeWeek(min: 16, max: 24, rain: 0.2, snow: 0, wind: 10)

        let result = try sut.rank(week: week)

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(Set(result.map(\.activity)).count, 4)
        XCTAssertTrue(result[0].score >= result[1].score)
        XCTAssertTrue(result[1].score >= result[2].score)
        XCTAssertTrue(result[2].score >= result[3].score)
    }

    private func makeWeek(min: Double, max: Double, rain: Double, snow: Double, wind: Double) -> [DailyWeather] {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return (0..<7).map { index in
            DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: index, to: start) ?? start,
                minTempC: min,
                maxTempC: max,
                precipitationMM: rain,
                snowfallCM: snow,
                maxWindKph: wind
            )
        }
    }
}
