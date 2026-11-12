import SwiftUI

/// The notch surface: one broad black notch — a flat-top, rounded-bottom bar as wide as
/// the content, anchored at the screen top so the physical notch sits embedded in its
/// centre. Now-playing hangs below the notch; hover reveals transport controls and a scrubber.
struct NotchView: View {
    let model: NowPlayingModel
    let notch: NotchMetrics

    private var track: NowPlaying? { model.current }
    private var expanded: Bool { track != nil && model.isHovered }

    private var islandSize: CGSize {
        NotchGeometry.islandSize(
            hasTrack: track != nil, hovered: model.isHovered, hud: model.hud != nil, notch: notch
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.allowsHitTesting(false)
            if track != nil || model.hud != nil {
                island
                    .onHover { model.isHovered = $0 }
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: expanded)
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: track)
                    .animation(.spring(duration: 0.4, bounce: 0.2), value: model.hud)
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
        if let hud = model.hud {
            hudContent(hud)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: islandSize.height - notch.height)
                .padding(.top, notch.height)
        } else if let track {
            VStack(spacing: 8) {
                trackRow(track)
                if expanded, track.duration > 0 {
                    Scrubber(elapsed: model.displayElapsed, duration: track.duration) { model.seek(to: $0) }
                        .transition(.opacity)
                }
            }
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

    private func hudContent(_ level: SystemLevel) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol(for: level))
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.22)).frame(height: 4)
                    Capsule().fill(.white).frame(width: geo.size.width * min(max(level.value, 0), 1), height: 4)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func symbol(for level: SystemLevel) -> String {
        switch level.kind {
        case .volume: "speaker.wave.2.fill"
        case .brightness: "sun.max.fill"
        case .battery: level.charging ? "bolt.fill" : "battery.100"
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

/// A thin draggable progress bar; reports the sought time on release.
private struct Scrubber: View {
    let elapsed: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    @State private var dragFraction: Double?

    var body: some View {
        GeometryReader { geo in
            let fraction = dragFraction ?? (duration > 0 ? clamp(elapsed / duration) : 0)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.22)).frame(height: 3)
                Capsule().fill(.white).frame(width: geo.size.width * fraction, height: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { dragFraction = clamp($0.location.x / geo.size.width) }
                    .onEnded { value in
                        let target = clamp(value.location.x / geo.size.width)
                        dragFraction = nil
                        onSeek(target * duration)
                    }
            )
        }
        .frame(height: 14)
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
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
