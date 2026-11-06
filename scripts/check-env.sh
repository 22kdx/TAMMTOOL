#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0
if command -v java >/dev/null 2>&1; then java -version 2>&1 || failed=1; else echo 'ERROR: Java not found; install the JDK required by your Android Gradle Plugin (typically JDK 17 for AGP 8).'; failed=1; fi
for app in orders-delivery marketer; do
  if [[ -f $ROOT/apps/$app/gradlew ]]; then echo "OK: $app Gradle wrapper";
  elif command -v gradle >/dev/null 2>&1; then echo "WARNING: $app wrapper missing; system Gradle available";
  else echo "ERROR: $app Gradle wrapper and system Gradle missing"; failed=1; fi
done
if command -v gradle >/dev/null 2>&1; then gradle --version || failed=1; fi
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
if [[ -n ${ANDROID_SDK_ROOT:-} && -n ${ANDROID_HOME:-} && $ANDROID_HOME != "$ANDROID_SDK_ROOT" ]]; then echo 'ERROR: ANDROID_HOME and ANDROID_SDK_ROOT differ'; failed=1; fi
if [[ -n $sdk && -d $sdk ]]; then
  echo "SDK: $sdk"
  for part in platforms build-tools; do
    if [[ ! -d $sdk/$part ]] || [[ -z $(find "$sdk/$part" -mindepth 1 -maxdepth 1 -type d -print -quit) ]]; then echo "ERROR: SDK $part missing"; failed=1; fi
  done
else echo 'ERROR: Set ANDROID_HOME or ANDROID_SDK_ROOT to an installed SDK'; failed=1; fi
adb=$(command -v adb || true); [[ -n $adb ]] || adb="${sdk:-/nonexistent}/platform-tools/adb"
if [[ -x $adb ]]; then "$adb" version || failed=1; else echo 'ERROR: ADB missing (required for installation, not compilation)'; failed=1; fi
exit "$failed"
