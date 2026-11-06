#!/usr/bin/env bash
# Compilation-only preflight; no downloads, license changes, or ADB requirement.
set -euo pipefail
[[ $# == 0 ]] || { echo 'Usage: check-sdk.sh (ANDROID_API_LEVEL=35 ANDROID_BUILD_TOOLS_VERSION=35.0.0)' >&2; exit 2; }
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
api=${ANDROID_API_LEVEL:-35}
version=${ANDROID_BUILD_TOOLS_VERSION:-35.0.0}
[[ $api =~ ^[0-9]+$ && $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][A-Za-z0-9]+)*$ ]] || { echo 'ERROR: Invalid SDK version.' >&2; exit 2; }
if [[ -n ${ANDROID_HOME:-} && -n ${ANDROID_SDK_ROOT:-} && $ANDROID_HOME != "$ANDROID_SDK_ROOT" ]]; then
  echo 'ERROR: ANDROID_HOME and ANDROID_SDK_ROOT differ.' >&2; exit 1
fi
[[ -n $sdk && -d $sdk ]] || { echo 'ERROR: Android SDK directory missing; set ANDROID_HOME.' >&2; exit 1; }
[[ -s $sdk/platforms/android-$api/android.jar ]] || { echo "ERROR: platforms;android-$api android.jar missing or empty." >&2; exit 1; }
for tool in aapt2 zipalign apksigner; do
  [[ -x $sdk/build-tools/$version/$tool ]] || { echo "ERROR: build-tools;$version/$tool missing or not executable." >&2; exit 1; }
done
echo "OK: Android API $api and build-tools $version at $sdk (file preflight only; not a build test)."
