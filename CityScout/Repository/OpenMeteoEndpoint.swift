import Foundation

enum OpenMeteoEndpoint {
    case geocodingSearch
    case forecast

    private var baseURL: String {
        switch self {
        case .geocodingSearch:
            return "https://geocoding-api.open-meteo.com"
        case .forecast:
            return "https://api.open-meteo.com"
        }
    }

    private var path: String {
        switch self {
        case .geocodingSearch:
            return "/v1/search"
        case .forecast:
            return "/v1/forecast"
        }
    }

    func makeURL(queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}
