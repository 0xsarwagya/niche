# Niche

**A free, open-source dynamic island for your Mac's notch.**

Niche turns the empty space around the notch into a live surface — now-playing
controls, weather, and heads-up feedback for volume and brightness — without a
subscription, an account, or a paid Apple Developer certificate.

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![CI](https://github.com/0xsarwagya/niche/actions/workflows/ci.yml/badge.svg)](https://github.com/0xsarwagya/niche/actions/workflows/ci.yml)

> Niche is in early development. The notch surface is live; the feature adapters
> are landing one seam at a time (see [Status](#status)). The first tagged
> release and Homebrew cask are on the way.

## Why Niche

- **Free and open source.** MIT licensed, no paywall, no telemetry.
- **No paid Apple account.** Niche is ad-hoc signed. You pay nothing; the only
  cost is a one-time [Open Anyway](#first-launch-open-anyway) step at first launch.
- **Bring your own weather.** Keyless by default; swap in any provider with a
  small config file. Keys live in your Keychain and are never logged.
- **Honest architecture.** Ports and adapters, so the parts Apple keeps breaking
  stay quarantined behind one swappable seam each.

## Install

### Homebrew (recommended)

```bash
brew install --cask --no-quarantine 0xsarwagya/tap/niche
```

`--no-quarantine` skips Gatekeeper's quarantine flag, so you can skip the
Open-Anyway step below.

### Direct download

1. Download `Niche.app` from the [Releases](https://github.com/0xsarwagya/niche/releases) page.
2. Move it to `/Applications`.
3. Follow [First launch: Open Anyway](#first-launch-open-anyway).

### First launch: Open Anyway

Niche is ad-hoc signed, not notarized (notarization needs a paid Apple Developer
account — see [Why Niche](#why-niche)). On macOS Sequoia, the first launch is
blocked:

1. Open **System Settings → Privacy & Security**.
2. Scroll to the message that *"Niche" was blocked*, and click **Open Anyway**.
3. Confirm with Touch ID or your password.

You only do this once. Building from source with a stable dev identity avoids it
entirely (see [CONTRIBUTING](CONTRIBUTING.md)).

## Bring your own weather

Niche ships with keyless weather from [Open-Meteo](https://open-meteo.com) — it
works out of the box with no account. To use a different provider, point Niche at
a declarative adapter config:

- an endpoint **URL template**,
- where your **API key** goes (header, query, or none),
- how to **map response fields** onto Niche's weather model.

API keys are stored in the macOS Keychain and never written to logs. Imported or
shared adapter configs are treated as untrusted: adapters must be **https** (non-local
host), responses are size-capped and time-limited, and the key is sent only to the
adapter's own host. A malformed adapter is dropped, falling back to Open-Meteo.

Drop adapters in `~/Library/Application Support/Niche/weather-providers.json`
(see [`apps/macos/Examples/weather-providers.sample.json`](apps/macos/Examples/weather-providers.sample.json)),
then pick one from the menu bar's **Weather Source** submenu — Niche asks for the key
there and stores it in the Keychain (never in the JSON). The format:

```json
[
  {
    "id": "openweathermap",
    "name": "OpenWeatherMap",
    "url": "https://api.example.com/now?lat={lat}&lon={lon}&units=metric",
    "keyParam": "appid",
    "keyHeader": null,
    "map": { "temperature": "main.temp", "condition": "weather.0.id", "observedAt": null }
  }
]
```

`{lat}`/`{lon}` are substituted per request; the key goes in `keyParam` (query) or
`keyHeader` (header); `map` holds dot-paths (array indices allowed) into the response.

## Ask from an agent

The notch doubles as a prompt surface: a script or agent can ask a question and get the
answer you type into the notch — no server, just files.

```bash
# free-text reply
answer=$(apps/macos/scripts/niche-ask.sh "Deploy to production?")

# tappable choices — prints the one you pick
answer=$(apps/macos/scripts/niche-ask.sh --choices "Deploy,Cancel" "Deploy to production?")
echo "you said: $answer"
```

Agents can also show a transient **status** (no reply) — a pulsing dot while working, a
check when done, red on failure:

```bash
apps/macos/scripts/niche-status.sh thinking "Running tests"
apps/macos/scripts/niche-status.sh success  "All green"
```

Under the hood: drop a file in `~/Library/Application Support/Niche/inbox/`. `<id>.ask` is a
question — plain text, or JSON `{"question": "...", "options": ["Deploy","Cancel"]}` for choices —
and Niche writes your reply to `<id>.reply`. `<id>.status` is JSON
`{"state": "thinking|success|failure|clear", "text": "..."}` and expects no reply. A question
never steals keyboard focus; you click the notch to answer. The CLIs just wrap that.

## Architecture

Niche is built as ports and adapters. The domain types (`WeatherSnapshot`,
`NowPlaying`) import nothing but Foundation; everything platform- or
vendor-specific sits behind a protocol so a single adapter can be swapped when
Apple changes a private framework.

| Seam | Port | Adapter |
| --- | --- | --- |
| Now playing | `NowPlayingSource` | [`ungive/mediaremote-adapter`](https://github.com/ungive/mediaremote-adapter) (perl-injected helper — the only route on macOS 15.4+) |
| Weather | `WeatherProvider` | `OpenMeteoProvider` (keyless, built in) + declarative bring-your-own providers |
| HUD (volume / brightness / Spaces) | per-seam protocols | DisplayServices & CGS system interfaces |

- **Swift 6**, strict concurrency.
- **SwiftUI** content hosted in an AppKit `NSPanel` notch surface.
- **XcodeGen** — `project.yml` is committed, the `.xcodeproj` is generated.
- **Swift Testing** for the pure logic.
- **Sparkle** for in-app updates (its own update key — works without Apple notarization).

## Project layout

```
apps/macos/          # the Swift app (XcodeGen)
apps/web/            # the Astro marketing site
.github/workflows/   # CI for both
```

The two apps share no code — this is one git repo with two independent builds,
nothing more.

## Build from source

```bash
# macOS app
cd apps/macos
xcodegen generate
open Niche.xcodeproj

# website
cd apps/web
npm install
npm run dev
```

Full dev setup, including a stable signing identity so TCC permission prompts
stop repeating, is in [CONTRIBUTING](CONTRIBUTING.md).

## Status

**Working**

- Notch `NSPanel` surface: borderless, non-activating, pinned at the notch across
  every Space.
- Now playing: live track, artist, album artwork, and a draggable scrubber, with
  hover-to-reveal play / pause / skip controls, via the vendored `ungive/mediaremote-adapter`.
- Volume & brightness HUD at the notch, replacing the system OSD (needs Accessibility permission).
- Battery HUD: charging plug-in/unplug and a red low-battery alert.
- Lively spring motion, trackpad haptics, and tap-the-island to play/pause.
- Right-click the notch for quick actions (timer, Settings, Quit); scroll over it to change volume.
- Countdown timers, started from a menu bar item (which also has Quit).
- Weather glance on hovering the idle notch (opt-in location; keyless Open-Meteo).
- Launch at login, toggled from the menu bar.
- Accent colour (equalizer, scrubber) derived from the album artwork.
- Settings window (⌘,): toggle each module, pick a custom accent, tune the HUD duration.
- Agent prompts: a script asks a question (`niche-ask`) and you answer it inline in the notch.

**Planned**

- Spaces HUD; multi-display.
- AirPods / Bluetooth battery.
- Declarative bring-your-own weather providers + Keychain key storage.
- Sparkle auto-updates.

## Contributing

Issues and pull requests are welcome. Start with [CONTRIBUTING](CONTRIBUTING.md)
and the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Found a vulnerability? See [SECURITY](SECURITY.md) for private reporting.

## Acknowledgements

- [ungive/mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) —
  the now-playing route on modern macOS.
- [Open-Meteo](https://open-meteo.com) — free, keyless weather.
- [Sparkle](https://sparkle-project.org) — the macOS update framework.

## License

[MIT](LICENSE) © 2026 Niche contributors.
