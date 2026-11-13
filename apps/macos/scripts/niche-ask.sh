#!/usr/bin/env bash
# Ask the Niche notch a question and print the user's reply to stdout.
#
# Free text:  niche-ask.sh "Deploy to production?"
# Choices:    niche-ask.sh --choices "Deploy,Cancel" "Deploy to production?"
#             (prints the chosen option)
set -euo pipefail

choices=""
if [ "${1:-}" = "--choices" ]; then
  choices="${2:-}"
  shift 2
fi
[ $# -ge 1 ] || { echo "usage: niche-ask.sh [--choices \"A,B,C\"] <question>" >&2; exit 2; }

dir="$HOME/Library/Application Support/Niche/inbox"
mkdir -p "$dir"
id="$(uuidgen)"

if [ -n "$choices" ]; then
  python3 -c 'import json,sys; print(json.dumps({"question": sys.argv[1], "options": [o for o in sys.argv[2].split(",") if o]}))' \
    "$*" "$choices" > "$dir/$id.ask"
else
  printf '%s' "$*" > "$dir/$id.ask"
fi

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
