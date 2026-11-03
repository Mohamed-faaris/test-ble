#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_cmd adb

APK="${1:-}"
if [[ -z "$APK" ]]; then
  ANDROID_DIR="$(find_android_dir)"
  APK="$(find "$ANDROID_DIR" -type f -path '*/build/outputs/apk/*/release/*.apk' -printf '%T@ %p\\n' | sort -nr | head -n1 | cut -d' ' -f2- || true)"
fi
[[ -n "$APK" && -f "$APK" ]] || die "Pass an APK path: scripts/install.sh path/to/release.apk"
"$SCRIPT_DIR/connect.sh" --check
if [[ -n "${ANDROID_SERIAL:-}" ]]; then adb -s "$ANDROID_SERIAL" install -r "$APK"; else adb install -r "$APK"; fi
log "Installed $(basename "$APK")"
