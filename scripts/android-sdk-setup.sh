#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --accept-licenses) export ANDROID_ACCEPT_LICENSES=1 ;;
  --help|-h) echo 'Usage: android-sdk-setup.sh [--accept-licenses]'; exit 0 ;;
  '') ;;
  *) echo 'ERROR: Unknown option. Use --accept-licenses or --help.' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo 'ERROR: Too many arguments.' >&2; exit 2; }
# Pin the command-line tools; override only with a trusted tools revision/checksum.
revision=${ANDROID_CMDLINE_TOOLS_REVISION:-11076708}
api=${ANDROID_API_LEVEL:-35}; build_tools=${ANDROID_BUILD_TOOLS_VERSION:-35.0.0}
sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}
[[ $(uname -s) == Linux ]] || { echo 'ERROR: Automatic SDK download currently supports Linux only.' >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo 'ERROR: Install a compatible JDK first.' >&2; exit 1; }
if [[ -n ${ANDROID_SDK_ROOT:-} && -n ${ANDROID_HOME:-} && $ANDROID_HOME != "$ANDROID_SDK_ROOT" ]]; then echo 'ERROR: ANDROID_HOME and ANDROID_SDK_ROOT differ.' >&2; exit 1; fi
mkdir -p "$sdk"
export ANDROID_HOME="$sdk" ANDROID_SDK_ROOT="$sdk"
manager="$sdk/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x $manager ]]; then
  for cmd in curl unzip; do command -v "$cmd" >/dev/null || { echo "ERROR: Install $cmd first." >&2; exit 1; }; done
  tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
  curl --fail --location --retry 3 "https://dl.google.com/android/repository/commandlinetools-linux-${revision}_latest.zip" -o "$tmp/tools.zip"
  if [[ -n ${ANDROID_CMDLINE_TOOLS_SHA256:-} ]]; then
    printf '%s  %s\n' "$ANDROID_CMDLINE_TOOLS_SHA256" "$tmp/tools.zip" | sha256sum -c -
  fi
  unzip -q "$tmp/tools.zip" -d "$tmp/extracted"
  mkdir -p "$sdk/cmdline-tools/latest"
  cp -R "$tmp/extracted/cmdline-tools/." "$sdk/cmdline-tools/latest/"
fi
# License acceptance must be explicit in local builds and CI.
if [[ ${ANDROID_ACCEPT_LICENSES:-0} == 1 ]]; then
  set +e
  yes | "$manager" --sdk_root="$sdk" --licenses
  result=${PIPESTATUS[1]}
  set -e
  [[ $result == 0 ]] || { echo 'ERROR: SDK license acceptance failed.' >&2; exit "$result"; }
else
  echo 'Licenses will be requested interactively; CI should set ANDROID_ACCEPT_LICENSES=1 after reviewing them.'
fi
"$manager" --sdk_root="$sdk" 'platform-tools' "platforms;android-$api" "build-tools;$build_tools"
if [[ -n ${GITHUB_ENV:-} ]]; then printf 'ANDROID_HOME=%s\nANDROID_SDK_ROOT=%s\n' "$sdk" "$sdk" >> "$GITHUB_ENV"; fi
if [[ -n ${GITHUB_PATH:-} ]]; then printf '%s\n' "$sdk/platform-tools" "$sdk/cmdline-tools/latest/bin" "$sdk/build-tools/$build_tools" >> "$GITHUB_PATH"; fi
printf 'SDK ready: %s\nFor local shells: export ANDROID_HOME="%s" ANDROID_SDK_ROOT="%s"\n' "$sdk" "$sdk" "$sdk"
