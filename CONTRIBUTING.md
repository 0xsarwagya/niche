# Contributing to Niche

Thanks for helping build Niche. This guide gets you from a clone to a running
build.

## Prerequisites

- **Xcode 16 or newer** (Swift 6, Swift Testing).
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — `brew install xcodegen`.
- **Node 20 or newer** (for the website).

## macOS app (`apps/macos`)

```bash
cd apps/macos
xcodegen generate          # regenerate Niche.xcodeproj from project.yml
open Niche.xcodeproj
```

The `.xcodeproj` is generated and git-ignored — **edit `project.yml`, never the
project file**. Build and test from the command line:

```bash
xcodebuild build -scheme Niche -destination 'platform=macOS'
xcodebuild test  -scheme Niche -destination 'platform=macOS'
```

### A stable dev signing identity (recommended)

Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) gives each rebuild a fresh identity, so
macOS re-prompts for Accessibility, Bluetooth, and other TCC permissions every
time. Create one self-signed certificate and reuse it so the grants stick:

1. **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name `Niche Dev`, Identity Type **Self Signed Root**, Certificate Type
   **Code Signing**.
3. Build against it:

   ```bash
   xcodebuild build -scheme Niche -destination 'platform=macOS' \
     CODE_SIGN_IDENTITY="Niche Dev"
   ```

## Website (`apps/web`)

```bash
cd apps/web
npm install
npm run dev      # local dev server
npm run build    # production build
```

## Coding standards

- **Architecture**: keep the domain pure. New platform or vendor code goes behind
  a port (protocol); don't reach around a seam.
- **Logging**: structured `os.Logger`, one logger per type, never log keys,
  tokens, or secrets.
- **Commits**: one-line [Conventional Commit](https://www.conventionalcommits.org)
  subjects, e.g. `feat(macos): add weather pill`.
- **Tests**: Swift Testing, one assertion per test.

## Pull requests

Keep PRs focused and small. CI must pass (both the macOS and web jobs). The PR
template asks for a short Summary, Changes, and Testing — fill it in.
