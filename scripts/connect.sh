#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_cmd adb

MODE="${1:-}"
if [[ "$MODE" == "--tcpip" ]]; then
  SERIAL="${2:-}"
  [[ -n "$SERIAL" ]] || die "Usage: scripts/connect.sh --tcpip <phone-ip>"
  adb tcpip 5555
  adb connect "$SERIAL"
  exit 0
fi

adb start-server
adb devices -l
if [[ "$MODE" == "--check" ]]; then
  COUNT="$(adb devices | awk 'NR>1 && $2=="device" {n++} END {print n+0}')"
  (( COUNT > 0 )) || die "No authorized Android device. Enable USB debugging and accept the RSA prompt."
  exit 0
fi

cat <<'HELP'
Connection helper:
  USB:   Enable Developer options > USB debugging, connect phone, accept RSA prompt.
  Wi-Fi: adb pair PHONE_IP:PAIRING_PORT, then adb connect PHONE_IP:CONNECT_PORT
  Pick:  export ANDROID_SERIAL=<device-id>
  Logs:  adb logcat -s BleForegroundService BleScanner
HELP
