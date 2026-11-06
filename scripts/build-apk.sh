#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
usage() { echo 'Usage: build-apk.sh [all|marketer|orders-delivery] [debug|release]
Also accepts: [debug|release] [all|marketer|orders-delivery]'; echo 'Signed release requires APK_KEYSTORE, APK_KEY_ALIAS, APK_STORE_PASSWORD, APK_KEY_PASSWORD.'; }
[[ ${1:-} != -h && ${1:-} != --help ]] || { usage; exit 0; }
app=${1:-all}; variant=${2:-debug}
# Preserve the coordinator branch's original argument order as well.
if [[ ${1:-} =~ ^(debug|release)$ ]]; then variant=$1; app=${2:-marketer}; fi
case "$app" in afghani|طلبات-الأفغاني) app=marketer;; orders|التوصيل) app=orders-delivery;; esac
[[ $# -le 2 && $app =~ ^(all|marketer|orders-delivery)$ && $variant =~ ^(debug|release)$ ]] || { usage >&2; exit 2; }
trap 'echo "ERROR: APK build failed (line $LINENO). See Gradle output above." >&2' ERR
if [[ $variant == release ]]; then
  for key in APK_KEYSTORE APK_KEY_ALIAS APK_STORE_PASSWORD APK_KEY_PASSWORD; do
    [[ -n ${!key:-} ]] || { echo "ERROR: $key is required for signed release." >&2; exit 1; }
  done
  [[ -f $APK_KEYSTORE ]] || { echo 'ERROR: keystore not found.' >&2; exit 1; }
  APK_KEYSTORE="$(cd -- "$(dirname -- "$APK_KEYSTORE")" && pwd)/$(basename -- "$APK_KEYSTORE")"
  export APK_KEYSTORE APK_KEY_ALIAS APK_STORE_PASSWORD APK_KEY_PASSWORD
  sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}
  apksigner=$(command -v apksigner || true)
  zipalign=$(command -v zipalign || true)
  if [[ -n $sdk && -d $sdk/build-tools ]]; then
    tools=$(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
    [[ -n $apksigner ]] || apksigner="$tools/apksigner"
    [[ -n $zipalign ]] || zipalign="$tools/zipalign"
  fi
  [[ -x $apksigner && -x $zipalign ]] || { echo 'ERROR: apksigner and zipalign are required; install Android build-tools.' >&2; exit 1; }
fi
apps=("$app"); [[ $app != all ]] || apps=(orders-delivery marketer)
for name in "${apps[@]}"; do
  project="$ROOT/apps/$name"
  [[ -d $project && ( -f $project/settings.gradle.kts || -f $project/settings.gradle ) ]] || { echo "ERROR: Android project missing: $project" >&2; exit 1; }
  if [[ -f $project/gradlew ]]; then gradle=(bash "$project/gradlew");
  elif command -v gradle >/dev/null 2>&1; then gradle=(gradle);
  else echo "ERROR: No Gradle wrapper or installed Gradle for $name." >&2; exit 1; fi
  task=assembleDebug; [[ $variant != release ]] || task=assembleRelease
  echo "Building $name ($variant)..."
  log_dir=${BUILD_LOG_DIR:-$ROOT/.build-logs}
  mkdir -p "$log_dir"
  echo "Gradle log: $log_dir/$name-$variant.log"
  # pipefail preserves Gradle failures while keeping a complete CI-readable log.
  (cd "$project"; "${gradle[@]}" --no-daemon --console=plain --stacktrace ":app:$task") 2>&1 | tee "$log_dir/$name-$variant.log"
  output="$project/app/build/outputs/apk/$variant"
  found=0
  while IFS= read -r -d '' apk; do
    [[ $apk != *-signed.apk && $apk != *-aligned.apk ]] || continue
    found=1
    if [[ $variant == release ]]; then
      aligned="${apk%.apk}-aligned.apk"; signed="${apk%.apk}-signed.apk"
      "$zipalign" -f -p 4 "$apk" "$aligned"
      "$apksigner" sign --ks "$APK_KEYSTORE" --ks-key-alias "$APK_KEY_ALIAS" --ks-pass env:APK_STORE_PASSWORD --key-pass env:APK_KEY_PASSWORD --out "$signed" "$aligned"
      "$apksigner" verify "$signed"
      rm -f -- "$aligned"
      apk=$signed
    fi
    "$ROOT/scripts/apk-test.sh" info "$apk"
  done < <(find "$output" -type f -name '*.apk' -print0 2>/dev/null)
  [[ $found == 1 ]] || { echo "ERROR: Gradle returned successfully but no APK found in $output." >&2; exit 1; }
done
