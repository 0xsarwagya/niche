import SwiftUI

/// The notch surface: one broad black notch anchored at the screen top with the physical
/// notch embedded in its centre. It shows (in priority) a transient volume/brightness/battery
/// HUD, a running timer, now-playing (hover-reveal controls + scrubber), or — when idle and
/// hovered — a weather glance. Idle renders a clear, hoverable footprint only.
struct NotchView: View {
    let model: NowPlayingModel
    let weather: WeatherModel
    let notch: NotchMetrics

    @State private var reply = ""
    @FocusState private var replyFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var track: NowPlaying? { model.current }
    private var expanded: Bool { track != nil && model.isHovered }

    private var reduced: Bool {
        NicheMotion.isReduced(Preferences.shared.motion, system: systemReduceMotion)
    }

    private var notchContent: NotchGeometry.Content {
        NotchView.resolveContent(model: model, weather: weather)
    }

    private var islandSize: CGSize {
        NotchGeometry.islandSize(content: notchContent, hovered: model.isHovered, notch: notch)
    }

    private var cornerRadius: CGFloat {
        NotchGeometry.cornerRadius(content: notchContent, hovered: model.isHovered)
    }

    private var accent: Color {
        let prefs = Preferences.shared
        if prefs.useCustomAccent { return prefs.customAccent }
        return model.accentColor ?? Preferences.defaultAccent
    }

    /// The single source of truth for what the island shows, honouring the enabled modules.
    /// Both the view and the panel's hit region call this so clicks match what is drawn.
    static func resolveContent(model: NowPlayingModel, weather: WeatherModel) -> NotchGeometry.Content {
        let prefs = Preferences.shared
        let hudEnabled: Bool
        switch model.hud?.kind {
        case .volume, .brightness: hudEnabled = prefs.showHUD
        case .battery: hudEnabled = prefs.showBattery
        case nil: hudEnabled = false
        }
        return NotchGeometry.content(
            prompt: model.prompt != nil,
            hasTrack: model.current != nil && prefs.showNowPlaying,
            hud: hudEnabled,
            timer: model.timerRemaining != nil,
            weather: model.isHovered && weather.snapshot != nil && prefs.showWeather
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.allowsHitTesting(false)
            island
                .onHover { hovering in
                    if hovering, track != nil { Haptics.expand() }
                    model.isHovered = hovering
                }
                .animation(NicheMotion.expand(reduced: reduced), value: expanded)
                .animation(NicheMotion.morph(reduced: reduced), value: track)
                .animation(NicheMotion.pulse(reduced: reduced), value: model.hud)
                .animation(NicheMotion.expand(reduced: reduced), value: model.prompt)
                .animation(NicheMotion.morph(reduced: reduced), value: model.timerRemaining != nil)
                .animation(NicheMotion.morph(reduced: reduced), value: notchContent)
        }
    }

    /// One persistent black shell: the stable object. It grows from the physical notch and its
    /// content morphs inside, rather than the whole island being torn down per state.
    private var island: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, style: .continuous)
            .fill(.black)
            .frame(width: islandSize.width, height: islandSize.height)
            .overlay(alignment: .top) { content }
            .shadow(color: .black.opacity(notchContent == .hidden ? 0 : 0.35), radius: 7, y: 3)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch notchContent {
            case .hidden:
                EmptyView()
            case .prompt:
                if let prompt = model.prompt { promptView(prompt) }
            case .hud:
                if let hud = model.hud {
                    levelRow(symbol: symbol(for: hud), fraction: hud.value, tint: hud.warning ? .red : .white)
                }
            case .timer:
                if let remaining = model.timerRemaining { timerRow(remaining) }
            case .nowPlaying:
                if let track { nowPlayingBody(track) }
            case .weather:
                if let snapshot = weather.snapshot { weatherRow(snapshot) }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: islandSize.height - notch.height)
        .padding(.top, notch.height)
    }

    // MARK: Now playing

    private func nowPlayingBody(_ track: NowPlaying) -> some View {
        VStack(spacing: 8) {
            trackRow(track)
            if expanded, track.duration > 0 {
                Scrubber(elapsed: model.displayElapsed, duration: track.duration, color: accent) { model.seek(to: $0) }
                    .transition(.opacity)
            }
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
                PlayingBars(isPlaying: track.isPlaying, color: accent, reduced: reduced).transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            model.togglePlayPause()
        }
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
            ControlButton(symbol: "backward.fill") { Haptics.tap(); model.previousTrack() }
            ControlButton(symbol: track.isPlaying ? "pause.fill" : "play.fill") { Haptics.tap(); model.togglePlayPause() }
            ControlButton(symbol: "forward.fill") { Haptics.tap(); model.nextTrack() }
        }
    }

    // MARK: HUD, timer, weather

    private func levelRow(symbol: String, fraction: Double, tint: Color) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 20)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.22)).frame(height: 4)
                    Capsule().fill(tint).frame(width: geo.size.width * min(max(fraction, 0), 1), height: 4)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timerRow(_ remaining: TimeInterval) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
            Text(NotchView.format(remaining))
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func promptView(_ prompt: AgentPrompt) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                Text(prompt.question)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                TextField("Reply…", text: $reply)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .focused($replyFocused)
                    .onSubmit(sendReply)
                Button(action: sendReply) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(prompt.id)
        .onAppear { replyFocused = true }
    }

    private func sendReply() {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        model.answer(text)
        reply = ""
        replyFocused = true
    }

    private func weatherRow(_ snapshot: WeatherSnapshot) -> some View {
        HStack(spacing: 11) {
            Image(systemName: NotchView.weatherSymbol(snapshot.conditionCode))
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 22)
            Text("\(Int(snapshot.temperatureCelsius.rounded()))°")
                .font(.system(size: 16, weight: .semibold))
            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func symbol(for level: SystemLevel) -> String {
        switch level.kind {
        case .volume: "speaker.wave.2.fill"
        case .brightness: "sun.max.fill"
        case .battery: level.warning ? "battery.25" : (level.charging ? "bolt.fill" : "battery.100")
        }
    }

    nonisolated static func format(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Maps a WMO weather code to an SF Symbol.
    nonisolated static func weatherSymbol(_ code: Int) -> String {
        switch code {
        case 0: "sun.max.fill"
        case 1...3: "cloud.sun.fill"
        case 45...48: "cloud.fog.fill"
        case 51...67: "cloud.rain.fill"
        case 71...77: "cloud.snow.fill"
        case 80...82: "cloud.heavy.rain.fill"
        case 95...99: "cloud.bolt.fill"
        default: "cloud.fill"
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
    let color: Color
    let onSeek: (TimeInterval) -> Void

    @State private var dragFraction: Double?

    var body: some View {
        GeometryReader { geo in
            let fraction = dragFraction ?? (duration > 0 ? clamp(elapsed / duration) : 0)
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.22)).frame(height: 3)
                Capsule().fill(color).frame(width: geo.size.width * fraction, height: 3)
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

/// Three accent bars that bounce while audio is playing; static when motion is reduced.
private struct PlayingBars: View {
    var isPlaying: Bool
    var color: Color
    var reduced: Bool

    @State private var high = false
    private let lows: [CGFloat] = [5, 5, 5]
    private let highs: [CGFloat] = [11, 16, 13]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: high && isPlaying ? highs[index] : lows[index])
            }
        }
        .frame(height: 16)
        .opacity(isPlaying ? 1 : 0.45)
        .animation(reduced ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: high)
        .onAppear { high = !reduced }
    }
}
