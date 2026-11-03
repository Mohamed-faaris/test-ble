#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_cmd java; require_cmd keytool

ANDROID_DIR="$(find_android_dir)"
GRADLEW="$(find_gradlew "$ANDROID_DIR")"
[[ -f "$ANDROID_DIR/keystore.properties" ]] || die "Missing android/keystore.properties. Run scripts/create-keys.sh first."

if [[ "${SKIP_WEB_SYNC:-0}" != "1" && -f "$PROJECT_ROOT/package.json" ]]; then
  if command -v pnpm >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
    (cd "$PROJECT_ROOT" && pnpm install --frozen-lockfile && pnpm build)
  elif command -v npm >/dev/null 2>&1; then
    (cd "$PROJECT_ROOT" && npm ci && npm run build)
  else
    die "Install pnpm or npm to build the frontend."
  fi
  if [[ -x "$PROJECT_ROOT/node_modules/.bin/cap" ]]; then
    (cd "$PROJECT_ROOT" && npx cap sync android)
  fi
fi

MODULE="${GRADLE_MODULE:-:app}"
TASK="${MODULE}:assembleRelease"
TASK="${TASK//::/:}"
log "Building signed release with $TASK"
"$GRADLEW" -p "$ANDROID_DIR" --no-daemon clean "$TASK"

mapfile -d '' ARTIFACTS < <(find "$ANDROID_DIR" -type f \\
  \\( -path '*/build/outputs/apk/*/release/*.apk' -o -path '*/build/outputs/bundle/*Release/*.aab' \\) -print0)
(("${#ARTIFACTS[@]}" > 0)) || die "No release APK/AAB produced. Check Gradle module and signing setup."

OUT="$(new_output_dir)"
mkdir -p "$OUT/artifacts"
for file in "${ARTIFACTS[@]}"; do
  rel="${file#"$ANDROID_DIR"/}"
  mkdir -p "$OUT/artifacts/$(dirname "$rel")"
  cp -v "$file" "$OUT/artifacts/$rel"
  if [[ "$file" == *.apk ]] && command -v apksigner >/dev/null 2>&1; then
    apksigner verify --verbose --print-certs "$file" > "$OUT/$(basename "$file").signature.txt"
  fi
done

{
  printf 'app_name=%s\\n' "$APP_NAME"
  printf 'built_at=%s\\n' "$(date --iso-8601=seconds)"
  printf 'gradle_module=%s\\n' "$MODULE"
  printf 'artifacts:\\n'
  printf '  %s\\n' "${ARTIFACTS[@]}"
} > "$OUT/build-info.txt"
log "Release artifacts copied to: $OUT"
