import Foundation

/// A volume or brightness change to surface briefly in the notch HUD.
struct SystemLevel: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case volume
        case brightness
        case battery
    }

    let kind: Kind
    let value: Double
    var charging: Bool = false
    var warning: Bool = false
}
