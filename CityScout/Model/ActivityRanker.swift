import Foundation

struct ActivityRanker {
    func rank(week: [DailyWeather]) throws -> [ActivityScore] {
        guard !week.isEmpty else {
            throw AppError.noForecastData
        }

        let averages = WeatherAverages(
            temperature: average(week, at: \.averageTempC),
            precipitation: average(week, at: \.precipitationMM),
            snowfall: average(week, at: \.snowfallCM),
            wind: average(week, at: \.maxWindKph)
        )

        let rules: [ActivityRule] = [
            makeRule(
                activity: .skiing,
                reason: "Snow and cold temperatures increase skiing suitability.",
                base: 0,
                component(.snowfall, .cappedLinear(multiplier: 8, cap: 55)),
                component(.temperature, .peak(target: -2, maxScore: 25, slope: 2)),
                component(.wind, .preferredUpperBound(threshold: 18, maxScore: 20, slope: 1.2))
            ),
            makeRule(
                activity: .surfing,
                reason: "Moderate wind and temperate weather favor surfing.",
                base: 30,
                component(.wind, .peak(target: 22, maxScore: 35, slope: 2)),
                component(.temperature, .peak(target: 20, maxScore: 20, slope: 1.3)),
                component(.precipitation, .cappedLinear(multiplier: 1.4, cap: 20), weight: -1)
            ),
            makeRule(
                activity: .outdoorSightseeing,
                reason: "Mild temperatures with low wind and rain favor outdoor sightseeing.",
                base: 10,
                component(.temperature, .peak(target: 21, maxScore: 45, slope: 3)),
                component(.precipitation, .preferredUpperBound(threshold: 0, maxScore: 30, slope: 4)),
                component(.wind, .preferredUpperBound(threshold: 12, maxScore: 20, slope: 1.8))
            ),
            makeRule(
                activity: .indoorSightseeing,
                reason: "Indoor activities score higher when weather is uncomfortable.",
                base: 15,
                component(.precipitation, .cappedLinear(multiplier: 5, cap: 35)),
                component(.temperature, .distanceFrom(target: 21, multiplier: 1.8, cap: 30)),
                component(.wind, .aboveThreshold(threshold: 15, multiplier: 1.2, cap: 20))
            )
        ]

        return rules.map { score(for: $0, averages: averages) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.activity.rawValue < rhs.activity.rawValue
                }
                return lhs.score > rhs.score
            }
    }

    private func score(for rule: ActivityRule, averages: WeatherAverages) -> ActivityScore {
        let raw = rule.components.reduce(rule.base) { partial, component in
            partial + component.score(using: averages)
        }
        return ActivityScore(activity: rule.activity, score: clamp(raw), reason: rule.reason)
    }

    private func makeRule(
        activity: ActivityType,
        reason: String,
        base: Double,
        _ components: RuleComponent...) -> ActivityRule {
        ActivityRule(activity: activity, reason: reason, base: base, components: components)
    }

    private func component(_ metric: WeatherMetric, _ formula: ScoreFormula, weight: Double = 1) -> RuleComponent {
        RuleComponent(metric: metric, formula: formula, weight: weight)
    }

    private func average<Value: BinaryFloatingPoint>(_ week: [DailyWeather], at keyPath: KeyPath<DailyWeather, Value>) -> Double {
        week.map { Double($0[keyPath: keyPath]) }.reduce(0, +) / Double(week.count)
    }

    private func clamp(_ value: Double) -> Int {
        Int(max(0, min(100, value)).rounded())
    }
}

private struct WeatherAverages {
    let temperature: Double
    let precipitation: Double
    let snowfall: Double
    let wind: Double
}

private struct ActivityRule {
    let activity: ActivityType
    let reason: String
    let base: Double
    let components: [RuleComponent]
}

private enum WeatherMetric {
    case temperature
    case precipitation
    case snowfall
    case wind

    func value(from averages: WeatherAverages) -> Double {
        switch self {
        case .temperature:
            averages.temperature
        case .precipitation:
            averages.precipitation
        case .snowfall:
            averages.snowfall
        case .wind:
            averages.wind
        }
    }
}

private enum ScoreFormula {
    case cappedLinear(multiplier: Double, cap: Double)
    case peak(target: Double, maxScore: Double, slope: Double)
    case preferredUpperBound(threshold: Double, maxScore: Double, slope: Double)
    case distanceFrom(target: Double, multiplier: Double, cap: Double)
    case aboveThreshold(threshold: Double, multiplier: Double, cap: Double)

    func evaluate(value: Double) -> Double {
        switch self {
        case let .cappedLinear(multiplier, cap):
            min(value * multiplier, cap)
        case let .peak(target, maxScore, slope):
            max(0, maxScore - abs(value - target) * slope)
        case let .preferredUpperBound(threshold, maxScore, slope):
            max(0, maxScore - max(0, value - threshold) * slope)
        case let .distanceFrom(target, multiplier, cap):
            min(max(0, abs(value - target) * multiplier), cap)
        case let .aboveThreshold(threshold, multiplier, cap):
            min(max(0, value - threshold) * multiplier, cap)
        }
    }
}

private struct RuleComponent {
    let metric: WeatherMetric
    let formula: ScoreFormula
    let weight: Double

    func score(using averages: WeatherAverages) -> Double {
        formula.evaluate(value: metric.value(from: averages)) * weight
    }
}
