import Foundation

/// A point-in-time weather reading, provider-agnostic. The domain imports nothing but Foundation.
struct WeatherSnapshot: Equatable, Sendable {
    let temperatureCelsius: Double
    let conditionCode: Int
    let observedAt: Date
}
