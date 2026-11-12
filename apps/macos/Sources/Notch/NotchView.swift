import SwiftUI

/// The notch surface: one broad black notch — a flat-top, rounded-bottom bar as wide as
/// the content, anchored at the screen top so the physical notch sits embedded in its
/// centre. Now-playing hangs in the area below the notch; hover reveals transport controls.
struct NotchView: View {
    let model: NowPlayingModel
    let notch: NotchMetrics

    private var track: NowPlaying? { model.current }
    private var expanded: Bool { track != nil && model.isHovered }

    private var islandSize: CGSize {
        NotchGeometry.islandSize(hasTrack: track != nil, hovered: model.isHovered, notch: notch)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.allowsHitTesting(false)
            if track != nil {
                island
                    .onHover { model.isHovered = $0 }
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: expanded)
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: track)
            }
        }
    }

    private var island: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20, style: .continuous)
            .fill(.black)
            .frame(width: islandSize.width, height: islandSize.height)
            .overlay(alignment: .top) { content }
            .shadow(color: .black.opacity(0.35), radius: 7, y: 3)
    }

    @ViewBuilder
    private var content: some View {
        if let track {
            trackRow(track)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: islandSize.height - notch.height)
                .padding(.top, notch.height)
        }
    }

    private func trackRow(_ track: NowPlaying) -> some View {
        HStack(spacing: 10) {
            artwork
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                if !track.artist.isEmpty {
                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.62))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var artwork: some View {
        Group {
            if let image = model.artwork {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.6, blue: 0.42),
                        Color(red: 1, green: 0.37, blue: 0.54),
                        Color(red: 0.55, green: 0.42, blue: 1),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .frame(width: 30, height: 30)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func transport(_ track: NowPlaying) -> some View {
        HStack(spacing: 14) {
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
    private let lows: [CGFloat] = [5, 5, 5]
    private let highs: [CGFloat] = [11, 16, 13]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.78, green: 0.97, blue: 0.32))
                    .frame(width: 3, height: high && isPlaying ? highs[index] : lows[index])
            }
        }
        .frame(height: 16)
        .opacity(isPlaying ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: high)
        .onAppear { high = true }
    }
}
