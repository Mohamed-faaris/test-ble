#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT/.." && pwd)"
APP_NAME="${APP_NAME:-test-ble}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$PROJECT_ROOT/output}"

log() { printf '[ble-build] %s\\n' "$*"; }
warn() { printf '[warning] %s\\n' "$*" >&2; }
die() { printf '[error] %s\\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

find_android_dir() {
  if [[ -n "${ANDROID_DIR:-}" ]]; then
    [[ -d "$ANDROID_DIR" ]] || die "ANDROID_DIR does not exist: $ANDROID_DIR"
    printf '%s' "$ANDROID_DIR"; return
  fi
  [[ -d "$PROJECT_ROOT/android" ]] || die "Cannot find android/. Run from the project root or set ANDROID_DIR."
  printf '%s' "$PROJECT_ROOT/android"
}

find_gradlew() {
  local dir="$1"
  [[ -f "$dir/gradlew" ]] || die "Gradle wrapper missing: $dir/gradlew"
  chmod +x "$dir/gradlew"
  printf '%s' "$dir/gradlew"
}

slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'; }

new_output_dir() {
  local stamp app target n=1
  stamp="$(date '+%Y%m%d-%H%M%S')"
  app="$(slug "$APP_NAME")"
  mkdir -p "$OUTPUT_ROOT"
  target="$OUTPUT_ROOT/${stamp}-${app}.app"
  while [[ -e "$target" ]]; do target="$OUTPUT_ROOT/${stamp}-${app}-${n}.app"; n=$((n+1)); done
  mkdir -p "$target"
  printf '%s' "$target"
}
