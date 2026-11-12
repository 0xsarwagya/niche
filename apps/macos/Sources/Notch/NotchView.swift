import SwiftUI

/// The notch surface. Empty for now: a rounded black pill approximating the hardware notch.
struct NotchView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.black)
    }
}
