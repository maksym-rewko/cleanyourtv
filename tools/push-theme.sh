#!/usr/bin/env bash
# Push the shared design to one TV, or all of them: merges themes/maksym/look.json (the design, edited once)
# with themes/maksym/tv/<tv>.json (what differs per TV: Live TV package, hidden apps), then calls tools/theme.sh.
# Any other file in themes/maksym/ (wallpaper.jpg, wallpapers/) is pushed too.
#
# Usage: tools/push-theme.sh sony            push to the Sony (address from TV_SONY in env.local.sh)
#        tools/push-theme.sh hisense         same for the Hisense
#        tools/push-theme.sh all             every TV that has a tv/<name>.json and an address
#        tools/push-theme.sh sony --dry      print the merged config.json and stop
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
[ -f env.sh ] && . ./env.sh
THEME="${THEME:-themes/maksym}"
PY=tools/venv/bin/python
[ -x "$PY" ] || { echo "run: python3 -m venv tools/venv && tools/venv/bin/pip install -r tools/requirements.txt" >&2; exit 1; }
TARGET="${1:?usage: push-theme.sh <sony|hisense|all> [--dry]}"
DRY="${2:-}"

push_one() {
  local name="$1" file="$THEME/tv/$1.json" var addr out
  [ -f "$file" ] || { echo "no $file: add it first (Live TV package and hidden apps for that TV)" >&2; return 1; }
  var="TV_$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')"
  addr="${!var:-}"
  out="$ROOT/themes/.build/$name"
  rm -rf "$out"; mkdir -p "$out"
  # Everything except the two source files, so wallpapers ride along.
  (cd "$THEME" && find . -mindepth 1 -maxdepth 1 ! -name look.json ! -name tv -exec cp -R {} "$out"/ \;)
  "$PY" -I -c '
import json, sys
look, tv, dest = sys.argv[1:4]
cfg = json.load(open(look)); cfg.update(json.load(open(tv)))
json.dump(cfg, open(dest, "w"), indent=2); open(dest, "a").write("\n")
' "$THEME/look.json" "$file" "$out/config.json"
  if [ "$DRY" = "--dry" ]; then echo "== $name"; cat "$out/config.json"; return 0; fi
  [ -n "$addr" ] || { echo "$var is empty: set it in env.local.sh" >&2; return 1; }
  echo "== pushing to $name ($addr)"
  TV_HOST="$addr" tools/theme.sh "$out"
}

if [ "$TARGET" = all ]; then
  for f in "$THEME"/tv/*.json; do
    n="$(basename "$f" .json)"
    var="TV_$(printf '%s' "$n" | tr '[:lower:]' '[:upper:]')"
    if [ -n "${!var:-}" ] || [ "$DRY" = "--dry" ]; then push_one "$n"; else echo "skipping $n: $var is empty"; fi
  done
else
  push_one "$TARGET"
fi
