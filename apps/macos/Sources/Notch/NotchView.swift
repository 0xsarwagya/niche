import SwiftUI

/// Hosts the notch surface and observes now-playing state.
struct NotchRoot: View {
    let model: NowPlayingModel

    var body: some View {
        NotchView(nowPlaying: model.current)
    }
}

/// The notch surface: a black island that morphs between an idle pill and a now-playing card.
struct NotchView: View {
    var nowPlaying: NowPlaying?

    private var expanded: Bool { nowPlaying != nil }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            UnevenRoundedRectangle(
                bottomLeadingRadius: expanded ? 22 : 16,
                bottomTrailingRadius: expanded ? 22 : 16,
                style: .continuous
            )
            .fill(.black)
            .frame(width: expanded ? 360 : 200, height: expanded ? 62 : 32)
            .overlay(alignment: .leading) {
                if let track = nowPlaying {
                    trackCard(track)
                        .padding(.horizontal, 13)
                        .transition(.opacity)
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 10, y: 3)
            .animation(.spring(duration: 0.5, bounce: 0.26), value: expanded)
        }
    }

    @ViewBuilder
    private func trackCard(_ track: NowPlaying) -> some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.6, blue: 0.42),
                        Color(red: 1, green: 0.37, blue: 0.54),
                        Color(red: 0.55, green: 0.42, blue: 1),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 42, height: 42)
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
            PlayingBars(isPlaying: track.isPlaying)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
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
