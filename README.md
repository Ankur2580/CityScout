# CityScout

CityScout is a SwiftUI iOS app that helps travelers decide what to do in a city by ranking activity suitability against the next 7 days of forecasted weather.

## a. Project Overview

CityScout solves a simple planning problem: given a city, which activities are worth doing this week based on the weather?

Core user flow:
1. Search for a city by name.
2. Pick a city from the live search results.
3. View a ranked list of activities (0-100 suitability score) with a short reason for each score.

Supported activity categories:
- Skiing
- Surfing
- Outdoor sightseeing
- Indoor sightseeing

## b. Platform and Tooling Choices

- Platform: iOS (SwiftUI)
- Language: Swift
- Concurrency: Swift Concurrency (`async/await`, `Task`, `Task` cancellation)
- Reactive glue: Combine, used only for debouncing the search text field
- Testing: XCTest
- Dependencies: none (no third-party packages)
- Project format: native Xcode project (`CityScout.xcodeproj`)

Build settings (from `project.pbxproj`):
- `SWIFT_VERSION = 5.0`
- `IPHONEOS_DEPLOYMENT_TARGET = 26.2`

These choices keep the app lightweight, avoid third-party dependency risk, and rely entirely on first-party Apple frameworks.

## c. Architecture and Technical Decisions

Pattern: MVVM + Repository, wired together with a lightweight dependency-injection builder.

Why this architecture was chosen:
- Keeps UI rendering, state orchestration, domain scoring logic, and network access independent of each other.
- Makes unit testing straightforward: view models and repositories accept injected closures/protocols instead of concrete network types.
- Centralizes async state transitions and cancellation in view models, avoiding scattered or duplicated race-condition handling.
- Leaves room to add caching, personalization, or new data sources later without reworking the UI layer.

Key technical decisions:
- View models are `@MainActor`-isolated so published UI state only ever mutates on the main actor.
- In-flight tasks are cancelled before starting a new request, preventing stale responses from overwriting newer state.
- Errors are modeled as a single typed `AppError` enum (no generic, stringly-typed error case), so every failure path is explicit and exhaustively handled.
- UI colors are centralized in one shared palette type and reused across screens instead of being hardcoded per view.
- Network calls are single-attempt by design; there is currently no retry/backoff layer in the repository.

## d. How to Build and Run the App

Using Xcode:
1. Open `CityScout.xcodeproj`.
2. Select the `CityScout` scheme.
3. Choose an iOS Simulator destination.
4. Run with `Cmd+R`.

Using the terminal:

```bash
xcodebuild \
  -project CityScout.xcodeproj \
  -scheme CityScout \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

No API keys, secrets, or `.env` configuration are required — the app only calls public Open-Meteo endpoints.

## e. How to Run Tests and Testing Strategy

Using Xcode:
- Select the `CityScout` scheme and press `Cmd+U`.

Using the terminal:

```bash
xcodebuild test \
  -project CityScout.xcodeproj \
  -scheme CityScout \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Testing strategy:
- Domain logic: `ActivityRankerTests` verifies empty-input error handling and that exactly four activities are returned, sorted descending by score.
- View models: `SearchViewModelTests` and `DestinationViewModelTests` cover idle/loading/success/failure state transitions, debounce behavior, and error message propagation.
- Repositories: `OpenMeteoRepositoriesTests` verifies JSON decoding, country-code fallback mapping, malformed-date handling, and that failures are not silently retried — all against an actor-based HTTP stub (no real network calls in tests).
- Concurrency safety: view-model and repository test classes are `@MainActor`-annotated where needed, and test doubles use `actor` isolation to stay Swift 6 concurrency-checking clean.

## f. API Usage Notes

Provider: Open-Meteo (public, no API key required).

Endpoints used:
- Geocoding search — `GET https://geocoding-api.open-meteo.com/v1/search`
  - Query params: `name`, `count=10`, `language=en`, `format=json`
- 7-day forecast — `GET https://api.open-meteo.com/v1/forecast`
  - Query params: `latitude`, `longitude`, `forecast_days=7`, `timezone=auto`, `daily=temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max`

Decoding:
- Both responses decode directly into model-layer types (`CitySearchResponse`/`CitySearchResult` and `ForecastResponse`/`ForecastDaily`) using `JSONDecoder.convertFromSnakeCase`.

Error handling:
- City search maps common non-2xx status codes (redirects, 400/401/403/404/408/429, 5xx) to specific `AppError` cases so failures are diagnosable.
- Forecast currently maps any non-2xx response to `forecastFailed(statusCode:)`, and decoding/network failures to `forecastUnavailable`. This is less granular than city search today (see Trade-Offs).

## g. Activity Recommendation Logic

Implemented in the `ActivityRanker` domain type.

Input: an array of 7 `DailyWeather` entries (min/max temperature, precipitation, snowfall, max wind).

Processing:
1. Average each weather signal (temperature, precipitation, snowfall, wind) across the 7-day window.
2. Score each activity using a small set of reusable formula shapes (capped-linear, peak, preferred-upper-bound, distance-from-target, above-threshold) applied to the relevant signals.
3. Sum a base score plus each weighted component score per activity.
4. Clamp the result to the `0...100` range.

Output: four `ActivityScore` values (skiing, surfing, outdoor sightseeing, indoor sightseeing), each with a score and a short human-readable reason, sorted descending by score with a stable name-based tie-break.

## h. Assumptions Made

- A 7-day forecast window is sufficient for trip-planning purposes at this stage.
- Returning the top 10 city search matches is enough for users to disambiguate their intended city.
- English-only copy is acceptable for the current scope.
- The device has network connectivity during normal use; no offline-first requirement exists yet.
- A deterministic, weather-only scoring model is acceptable without user personalization or preferences.

## i. Trade-Offs and Omissions

Trade-offs made:
- Repositories perform a single request attempt with no retry/backoff, so behavior is predictable and easy to test, but a transient network blip or momentary 5xx surfaces as an immediate user-facing failure instead of being retried.
- Errors are modeled as one exhaustive `AppError` enum instead of a generic/passthrough error type, so every failure path is explicit and testable, but every new failure case (for example a new HTTP status to handle) must be added to the enum and its `message` mapping by hand.
- City search and forecast do not have equivalent error granularity: `OpenMeteoCitySearchRepository` maps roughly eight distinct status groups (redirect, 400, 401, 403, 404, 408, 429, 5xx) to specific cases, while `OpenMeteoWeatherRepository` collapses all non-2xx responses into a single `forecastFailed(statusCode:)` case and all decode/network failures into `forecastUnavailable`.

Explicitly out of scope for now:
- No local caching or persistence layer (every screen visit re-fetches data).
- No automatic location detection — city search is always manual.
- No localization/internationalization support.
- No UI/snapshot test suite.
- No analytics or telemetry instrumentation.

## j. Production-Readiness Notes

Before shipping this to production, the following would be prioritized:
- Add response caching (e.g. `URLCache` or a lightweight persistence layer) to reduce redundant network calls.
- Add network reachability detection and clearer offline messaging.
- Reintroduce a retry/backoff policy for transient failures, tuned per endpoint.
- Bring forecast error mapping to the same granularity as city-search error mapping.
- Add localization (`.xcstrings`) and run an accessibility audit (Dynamic Type, VoiceOver, contrast).
- Stand up a CI pipeline that builds, runs tests, and fails on new warnings.
- Add UI automation tests covering the search-to-destination-to-ranking flow end to end.

## k. Cross-Platform Delivery Notes

- The domain layer (activity scoring) and data layer (API contracts, error mapping) are already decoupled from SwiftUI, which makes them straightforward to port.
- The activity-ranking rules are expressed as plain data plus small formulas, so they translate directly into a functional spec usable on Android (Kotlin) or web (TypeScript) without needing to reverse-engineer UI code.
- Repository interfaces are narrow (a single method each), so platform-specific networking implementations can be swapped in while keeping the same contract and error semantics.
- A shared cross-platform spec would need three pieces: the endpoint/query contract, the error-mapping contract, and the scoring-formula contract — all three currently exist as isolated, portable units in this codebase.

## l. AI Usage Disclosure

AI assistance was used during development for:
- Refactoring support (for example, extracting reusable rule/formula abstractions, centralizing error types).
- Diagnosing and fixing compiler warnings (actor-isolation issues, Swift 6 concurrency warnings in tests).
- Drafting and iterating on this documentation.

Verification standard applied:
- Every code change was checked against the actual project files before and after editing, not assumed from memory or prior conversation.
- Build and test output (via `xcodebuild`) was inspected directly to confirm warnings/errors were actually resolved, rather than trusting the edit alone.
- This document was cross-checked against current source files (models, repositories, view models, views, tests, and project settings) rather than being written from unverified assumptions.

AI output was not accepted blindly — changes were validated through compiler diagnostics, test runs, and direct inspection of resulting source code.
