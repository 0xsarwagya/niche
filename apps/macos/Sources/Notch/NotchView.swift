import SwiftUI

/// The notch surface: a black island that morphs between an idle pill, a compact
/// now-playing card, and an expanded card with transport controls on hover.
struct NotchView: View {
    let model: NowPlayingModel

    private var track: NowPlaying? { model.current }
    private var expanded: Bool { track != nil && model.isHovered }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.allowsHitTesting(false)
            island
                .onHover { model.isHovered = $0 }
                .animation(.spring(duration: 0.42, bounce: 0.24), value: expanded)
                .animation(.spring(duration: 0.42, bounce: 0.24), value: track)
        }
    }

    private var islandSize: CGSize {
        NotchGeometry.islandSize(hasTrack: track != nil, hovered: model.isHovered)
    }

    private var island: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20, style: .continuous)
            .fill(.black)
            .frame(width: islandSize.width, height: islandSize.height)
            .overlay(alignment: .leading) { content }
            .shadow(color: .black.opacity(0.5), radius: 10, y: 3)
    }

    @ViewBuilder
    private var content: some View {
        if let track {
            HStack(spacing: 11) {
                artwork
                VStack(alignment: .leading, spacing: 1) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    if !track.artist.isEmpty {
                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 6)
                if expanded {
                    transport(track).transition(.opacity)
                } else {
                    PlayingBars(isPlaying: track.isPlaying).transition(.opacity)
                }
            }
            .padding(.horizontal, 13)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(LinearGradient(
                colors: [
                    Color(red: 1, green: 0.6, blue: 0.42),
                    Color(red: 1, green: 0.37, blue: 0.54),
                    Color(red: 0.55, green: 0.42, blue: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 34, height: 34)
    }

    private func transport(_ track: NowPlaying) -> some View {
        HStack(spacing: 13) {
            ControlButton(symbol: "backward.fill") { model.previousTrack() }
            ControlButton(symbol: track.isPlaying ? "pause.fill" : "play.fill") { model.togglePlayPause() }
            ControlButton(symbol: "forward.fill") { model.nextTrack() }
        }
    }
}

private struct ControlButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}

/// Three lime bars that bounce while audio is playing.
private struct PlayingBars: View {
    var isPlaying: Bool

    @State private var high = false
    private let lows: [CGFloat] = [6, 6, 6]
    private let highs: [CGFloat] = [12, 18, 14]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.78, green: 0.97, blue: 0.32))
                    .frame(width: 3, height: high && isPlaying ? highs[index] : lows[index])
            }
        }
        .frame(height: 18)
        .opacity(isPlaying ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: high)
        .onAppear { high = true }
    }
}
