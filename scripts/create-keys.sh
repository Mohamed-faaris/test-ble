#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_cmd keytool

ANDROID_DIR="$(find_android_dir)"
KEY_DIR="${KEY_DIR:-$PROJECT_ROOT/keystore}"
KEYSTORE_FILE="${KEYSTORE_FILE:-$KEY_DIR/release.keystore}"
KEY_ALIAS="${KEY_ALIAS:-testble-release}"

mkdir -p "$KEY_DIR"; chmod 700 "$KEY_DIR"
[[ ! -e "$KEYSTORE_FILE" ]] || die "Keystore already exists: $KEYSTORE_FILE (will not overwrite it)"

read -rsp 'Keystore password: ' STORE_PASSWORD; printf '\\n'
read -rsp 'Confirm password: ' STORE_PASSWORD_CONFIRM; printf '\\n'
[[ "$STORE_PASSWORD" == "$STORE_PASSWORD_CONFIRM" ]] || die "Passwords do not match"
(( ${#STORE_PASSWORD} >= 8 )) || die "Use at least 8 characters"
read -rsp 'Key password (Enter to reuse keystore password): ' KEY_PASSWORD; printf '\\n'
KEY_PASSWORD="${KEY_PASSWORD:-$STORE_PASSWORD}"

export STORE_PASSWORD KEY_PASSWORD
keytool -genkeypair -v \\
  -keystore "$KEYSTORE_FILE" -alias "$KEY_ALIAS" \\
  -keyalg RSA -keysize 4096 -validity 10000 -storetype PKCS12 \\
  -storepass:env STORE_PASSWORD -keypass:env KEY_PASSWORD \\
  -dname "CN=${KEY_CN:-Android Release}, OU=${KEY_OU:-Mobile}, O=${KEY_ORG:-Personal}, L=${KEY_CITY:-Trichy}, ST=${KEY_STATE:-Tamil Nadu}, C=${KEY_COUNTRY:-IN}"

PROPERTIES="$ANDROID_DIR/keystore.properties"
umask 077
cat > "$PROPERTIES" <<PROPS
storeFile=$KEYSTORE_FILE
storePassword=$STORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
PROPS
chmod 600 "$PROPERTIES" "$KEYSTORE_FILE"

IGNORE="$PROJECT_ROOT/.gitignore"; touch "$IGNORE"
for entry in 'keystore/' 'android/keystore.properties' '*.jks' '*.keystore' 'output/'; do
  grep -Fxq "$entry" "$IGNORE" || printf '%s\\n' "$entry" >> "$IGNORE"
done
unset STORE_PASSWORD STORE_PASSWORD_CONFIRM KEY_PASSWORD
log "Created signing keystore and private Gradle properties."
warn "Back up the keystore and passwords securely. Never commit them."
