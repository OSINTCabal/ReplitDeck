#!/usr/bin/env bash
# ReplitDeck updater. Source: Replit's official Linux feed (electron-builder latest-linux.yml).
#  --check    exit 10 if newer version available, 0 if current, 1 on error
#  --apply    download .deb, verify sha512+size from feed, install new versions/<ver>, flip current; keeps 2
#  --rollback switch current to the previous installed version
#  --restart  relaunch after apply/rollback
set -euo pipefail
ROOT="${REPLITDECK_ROOT:-$HOME/.local/opt/replitdeck}"; CUR="$ROOT/current"
FEED="${REPLITDECK_FEED:-https://desktop-updates.replit.com/desktop-app/updates/stable/linux/x64}"
MODE=check; RESTART=0
for a in "$@"; do case "$a" in --check) MODE=check;; --apply|--timer) MODE=apply;; --rollback) MODE=rollback;; --restart) RESTART=1;;
  -h|--help) sed -n '2,7p' "$0"; exit 0;; *) echo "unknown arg $a"; exit 1;; esac; done
HAVE=$(cat "$CUR/VERSION" 2>/dev/null || echo 0.0.0)
INTEGRATION="${REPLITDECK_SOURCE:-$ROOT/integration}"
restart() { [ "$RESTART" = 1 ] || return 0; local match; match=$(printf '%s\n' "$ROOT" | sed 's/[][\\.^$*+?(){}|]/\\&/g'); pkill -u "$(id -u)" -f "^$match/(current|versions/[^/]+)/replitdeck( |$)" || true; sleep 2; setsid "${XDG_BIN_HOME:-$HOME/.local/bin}/replitdeck" >/dev/null 2>&1 & }
if [ "$MODE" = rollback ]; then
  CURRENT=$(readlink -f "$CUR")
  PREV=$(for dir in "$ROOT"/versions/*; do if [[ -f $dir/VERSION && $(readlink -f "$dir") != "$CURRENT" ]]; then printf '%s\n' "$dir"; fi; done | sort -V | tail -1)
  [ -n "$PREV" ] || { echo "No previous version to roll back to"; exit 1; }
  ln -sfn "$PREV" "$ROOT/current.new" && mv -Tf "$ROOT/current.new" "$CUR"; echo "Rolled back $HAVE -> $(cat "$PREV/VERSION")"; restart; exit 0
fi
YML=$(curl -fsSL -m 30 "$FEED/latest-linux.yml") || { echo "Could not fetch update feed"; exit 1; }
LATEST=$(printf '%s\n' "$YML" | sed -n 's/^version: *//p' | head -1)
P=$(printf '%s\n' "$YML" | sed -n 's/^path: *//p' | head -1)
SHA=$(printf '%s\n' "$YML" | sed -n 's/^sha512: *//p' | head -1)
SIZE=$(printf '%s\n' "$YML" | sed -n 's/^ *size: *//p' | head -1)
[ -n "$LATEST" ] && [ -n "$P" ] && [ -n "$SHA" ] || { echo "Malformed feed"; exit 1; }
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$2" ]; }
if ! newer "$HAVE" "$LATEST"; then echo "Up to date (ReplitDeck $HAVE)"; exit 0; fi
echo "Update available: $HAVE -> $LATEST"
[ "$MODE" = check ] && exit 10
mkdir -p "$ROOT/versions"
exec 9>"$ROOT/.install.lock"; flock -n 9 || { echo "Another update is running" >&2; exit 1; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/r.deb" "$FEED/$P"
[ -z "$SIZE" ] || [ "$(stat -c%s "$TMP/r.deb")" = "$SIZE" ] || { echo "size mismatch"; exit 1; }
GOT=$(python3 -c 'import hashlib,base64,sys;print(base64.b64encode(hashlib.sha512(open(sys.argv[1],"rb").read()).digest()).decode())' "$TMP/r.deb")
[ "$GOT" = "$SHA" ] || { echo "sha512 mismatch"; exit 1; }
# extract .deb without dpkg: ar + tar (bsdtar or python fallback)
mkdir "$TMP/x"; cd "$TMP/x"
ar x ../r.deb
mkdir data; tar -xf data.tar.* -C data
[[ $LATEST =~ ^[0-9]+(\.[0-9]+)+$ ]] || { echo "Invalid version" >&2; exit 1; }
NEW=$(mktemp -d "$ROOT/versions/.stage-XXXXXX")
cp -a data/usr/lib/replit/. "$NEW/"; mv "$NEW/Replit" "$NEW/replitdeck"
cp -a "$INTEGRATION/libexec" "$INTEGRATION/share" "$NEW/"; [ ! -d "$INTEGRATION/systemd" ] || cp -a "$INTEGRATION/systemd" "$NEW/"; echo "$LATEST" > "$NEW/VERSION"
M=$(ldd "$NEW/replitdeck" 2>/dev/null | grep "not found" || true); [ -z "$M" ] || { echo "Missing runtime libraries: $M" >&2; exit 1; }
DEST="$ROOT/versions/$LATEST-$$"; mv "$NEW" "$DEST"
ln -sfn "$DEST" "$ROOT/current.new" && mv -Tf "$ROOT/current.new" "$CUR"
# Retain old versions so an active runtime is never pruned.
echo "Updated to $LATEST (rollback: $ROOT/libexec/update.sh --rollback)"; restart
