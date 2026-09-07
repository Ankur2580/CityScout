import SwiftUI

enum UIStrings {
    enum App {
        static let title = "CityScout"
    }

    enum Search {
        static let heroTitle = "Plan smarter trips"
        static let heroSubtitle = "Find top activities from the next 7 days of weather"
        static let searchPrompt = "Search city (e.g. Tokyo)"
        static let readyTitle = "Ready to explore"
        static let readySubtitle = "Start typing a city name. Results will appear automatically."
        static let searchingMessage = "Finding matching cities..."
        static let noResultsMessage = "No cities found for your search."
    }

    enum Destination {
        static let analysisTitle = "7-Day Forecast Analysis"
        static let retryButton = "Try again"

        static func analysisSubtitle(city: City) -> String {
            "Ranked activity suitability for \(city.name), \(city.country)."
        }
    }
}

enum UIValues {
    enum Search {
        static let stackSpacing: CGFloat = 18
        static let horizontalPadding: CGFloat = 18
        static let bottomPadding: CGFloat = 32
        static let titleTopPadding: CGFloat = 8
        static let titleSpacing: CGFloat = 4
        static let titleSize: CGFloat = 20
        static let subtitleSize: CGFloat = 14
        static let toolbarTitleSize: CGFloat = 24
        static let searchBarSpacing: CGFloat = 10
        static let searchBarPadding: CGFloat = 14
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 18
        static let rowCornerRadius: CGFloat = 16
        static let rowPadding: CGFloat = 14
        static let rowTitleSize: CGFloat = 18
        static let rowSubtitleSize: CGFloat = 13
        static let rowSpacing: CGFloat = 2
        static let listSpacing: CGFloat = 10
        static let infoTitleSize: CGFloat = 18
        static let infoBodySize: CGFloat = 14
        static let searchingSize: CGFloat = 15
        static let cardStroke: CGFloat = 1
    }

    enum Destination {
        static let stackSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 18
        static let bottomPadding: CGFloat = 30
        static let loadingTopPadding: CGFloat = 40
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 18
        static let cardStroke: CGFloat = 1
        static let headerTitleSize: CGFloat = 20
        static let headerSubtitleSize: CGFloat = 14
        static let headerSpacing: CGFloat = 6
        static let errorSpacing: CGFloat = 12
        static let errorTextSize: CGFloat = 14
        static let retryTextSize: CGFloat = 14
        static let retryHorizontalPadding: CGFloat = 14
        static let retryVerticalPadding: CGFloat = 8
        static let activityCardPadding: CGFloat = 14
        static let activityCardCornerRadius: CGFloat = 16
        static let activityHeaderSize: CGFloat = 16
        static let activityReasonSize: CGFloat = 13
        static let progressHeight: CGFloat = 8
        static let progressMinWidth: CGFloat = 18
        static let scoreHorizontalPadding: CGFloat = 10
        static let scoreVerticalPadding: CGFloat = 6
    }
}
