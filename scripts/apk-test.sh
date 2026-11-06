#!/usr/bin/env bash
set -euo pipefail
usage() { echo 'Usage: apk-test.sh info APK | install APK [DEVICE_SERIAL] | test APK [DEVICE_SERIAL] | launch PACKAGE [DEVICE_SERIAL] | devices'; }
[[ ${1:-} != --help && ${1:-} != -h ]] || { usage; exit 0; }
action=${1:-}; apk=${2:-}
[[ $action == devices && $# -eq 1 || $action == launch && -n $apk && $# -ge 2 && $# -le 3 || $action =~ ^(info|install|test)$ && -f $apk && $# -ge 2 && $# -le 3 ]] || { usage >&2; echo 'ERROR: Supply an existing APK.' >&2; exit 2; }
if [[ $action == info ]]; then
  echo "APK: $apk"; echo "Size: $(wc -c < "$apk" | tr -d ' ') bytes"
  aapt=$(command -v aapt || true)
  sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
  if [[ -z $aapt && -n $sdk && -d $sdk/build-tools ]]; then
    aapt=$(find "$sdk/build-tools" -type f -name aapt | sort -V | tail -n 1)
  fi
  if [[ -n $aapt && -x $aapt ]]; then
    "$aapt" dump badging "$apk" | awk '/^package:/{print; found=1} END {if (!found) exit 1}'
  else
    echo 'WARNING: aapt not found; package name and version unavailable. Install SDK build-tools.' >&2
  fi
  exit 0
fi
adb=$(command -v adb || true)
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
[[ -n $adb ]] || adb="${sdk:-/nonexistent}/platform-tools/adb"
[[ -x $adb ]] || { echo 'ERROR: ADB not found. Install platform-tools or set ANDROID_HOME.' >&2; exit 1; }
"$adb" start-server
if [[ $action == devices ]]; then exec "$adb" devices -l; fi
listing=$("$adb" devices)
serial=${3:-${ANDROID_SERIAL:-}}
if [[ -n $serial ]]; then
  state=$(awk -v serial="$serial" '$1 == serial {print $2}' <<< "$listing")
  [[ $state == device ]] || { echo "ERROR: Device $serial unavailable (state: ${state:-not connected}). Authorize USB debugging and reconnect." >&2; exit 1; }
else
  devices=(); while read -r id state rest; do [[ $state != device ]] || devices+=("$id"); done <<< "$listing"
  [[ ${#devices[@]} -gt 0 ]] || { echo 'ERROR: No authorized devices connected. Connect a device, enable USB debugging, accept authorization; check adb devices.' >&2; exit 1; }
  [[ ${#devices[@]} -eq 1 ]] || { echo 'ERROR: Multiple devices connected. Specify DEVICE_SERIAL or ANDROID_SERIAL.' >&2; exit 1; }
  serial=${devices[0]}
fi
if [[ $action == launch ]]; then
  [[ $apk =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] || { echo 'ERROR: Invalid package name.' >&2; exit 2; }
  exec "$adb" -s "$serial" shell monkey -p "$apk" -c android.intent.category.LAUNCHER 1
fi
if [[ $action == test ]]; then
  # Resolve the package before installing. Never uninstall either app or erase its data.
  details=$(bash "${BASH_SOURCE[0]}" info "$apk")
  package=$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<< "$details")
  [[ -n $package ]] || { echo 'ERROR: Cannot determine package; install aapt from SDK build-tools.' >&2; exit 1; }
fi
"$adb" -s "$serial" install -r "$apk"
if [[ $action == test ]]; then
  bash "${BASH_SOURCE[0]}" launch "$package" "$serial"
  echo 'Install and launch completed; this is a smoke test, not a functional test.'
fi
