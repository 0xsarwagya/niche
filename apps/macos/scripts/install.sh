#!/usr/bin/env bash
# Build Niche (Release) and install it to /Applications.
#
# A Release build is signed ad-hoc WITHOUT get-task-allow. That matters:
# macOS will not persist Accessibility (or other sensitive) permissions for a
# debuggable app, so a Debug build re-asks for them on every launch.
set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED="$(mktemp -d)"
trap 'rm -rf "$DERIVED"' EXIT
APP="$DERIVED/Build/Products/Release/Niche.app"
DEST="/Applications/Niche.app"

command -v xcodegen >/dev/null 2>&1 && xcodegen generate
xcodebuild build -scheme Niche -configuration Release \
  -derivedDataPath "$DERIVED" -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO >/dev/null

if codesign -d --entitlements :- "$APP" 2>/dev/null | grep -q get-task-allow; then
  echo "error: build is debuggable (get-task-allow); refusing to install" >&2
  exit 1
fi

osascript -e 'quit app "Niche"' 2>/dev/null || true
rm -rf "$DEST"
cp -R "$APP" "$DEST"
tccutil reset Accessibility com.niche.app >/dev/null 2>&1 || true
open "$DEST"

echo "Installed to $DEST."
echo "Grant Accessibility once: System Settings > Privacy & Security > Accessibility."
