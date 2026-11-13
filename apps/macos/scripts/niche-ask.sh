#!/usr/bin/env bash
# Ask the Niche notch a question and print the user's reply to stdout.
# Usage: niche-ask.sh "Deploy to production?"
set -euo pipefail

[ $# -ge 1 ] || { echo "usage: niche-ask.sh <question>" >&2; exit 2; }

dir="$HOME/Library/Application Support/Niche/inbox"
mkdir -p "$dir"
id="$(uuidgen)"
printf '%s' "$*" > "$dir/$id.ask"

reply="$dir/$id.reply"
waited=0
while [ ! -f "$reply" ]; do
  sleep 0.2
  waited=$((waited + 1))
  if [ "$waited" -gt 1500 ]; then
    rm -f "$dir/$id.ask"
    echo "niche-ask: timed out after 5 minutes" >&2
    exit 1
  fi
done

cat "$reply"
rm -f "$reply"
