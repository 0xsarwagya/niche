import Foundation

/// A point-in-time weather reading, provider-agnostic. The domain imports nothing but Foundation.
/// The day's high/low are optional, since not every provider supplies a daily forecast.
struct WeatherSnapshot: Equatable, Sendable {
    let temperatureCelsius: Double
    let conditionCode: Int
    let observedAt: Date
    let highCelsius: Double?
    let lowCelsius: Double?

    init(
        temperatureCelsius: Double,
        conditionCode: Int,
        observedAt: Date,
        highCelsius: Double? = nil,
        lowCelsius: Double? = nil
    ) {
        self.temperatureCelsius = temperatureCelsius
        self.conditionCode = conditionCode
        self.observedAt = observedAt
        self.highCelsius = highCelsius
        self.lowCelsius = lowCelsius
    }
}
