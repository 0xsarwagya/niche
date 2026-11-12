import Foundation

/// A volume or brightness change to surface briefly in the notch HUD.
struct SystemLevel: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case volume
        case brightness
    }

    let kind: Kind
    let value: Double
}
