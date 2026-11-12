# Vendored: mediaremote-adapter

Source: https://github.com/ungive/mediaremote-adapter (BSD 3-Clause, see `LICENSE`)
Commit: `14eed9389241d06e29f7326c19e9ebc6ec8a5f36`

This is the only route to now-playing on macOS 15.4+: `/usr/bin/perl` is Apple-signed
and entitled to the private MediaRemote framework, so it loads `MediaRemoteAdapter.framework`
and streams now-playing as JSON. The framework is **bundled, not linked** — Niche only
passes its path to the script (see `MediaRemoteNowPlayingSource`).

`MediaRemoteAdapter.framework` is prebuilt (universal: x86_64 + arm64). To rebuild:

```bash
git clone https://github.com/ungive/mediaremote-adapter.git
cd mediaremote-adapter && mkdir build && cd build && cmake .. && cmake --build .
# then copy build/MediaRemoteAdapter.framework and bin/mediaremote-adapter.pl here
```
