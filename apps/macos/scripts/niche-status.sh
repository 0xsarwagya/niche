#!/usr/bin/env bash
# Post a transient status to the Niche notch — no reply, fire and forget.
#
#   niche-status.sh thinking "Running tests"   # pulsing dot, stays until replaced/cleared
#   niche-status.sh success  "All green"       # check + haptic, auto-dismisses
#   niche-status.sh failure  "2 tests failed"  # red, nudges, auto-dismisses
#   niche-status.sh clear                      # remove the current status
set -euo pipefail

[ $# -ge 1 ] || { echo "usage: niche-status.sh <thinking|success|failure|clear> [text]" >&2; exit 2; }
state="$1"; shift
text="${*:-}"

dir="$HOME/Library/Application Support/Niche/inbox"
mkdir -p "$dir"
id="$(uuidgen)"
python3 -c 'import json,sys; print(json.dumps({"state": sys.argv[1], "text": sys.argv[2]}))' \
  "$state" "$text" > "$dir/$id.status"
