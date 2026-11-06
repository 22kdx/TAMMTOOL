#!/usr/bin/env bash
# CI entry point: preserve the real build status and collect diagnostics without Git writes.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
app=${1:-marketer}
[[ $app != --help && $app != -h ]] || { echo 'Usage: diagnose-apk.sh [marketer|orders-delivery|all]'; exit 0; }
[[ $# -le 1 && $app =~ ^(marketer|orders-delivery|all)$ ]] || { echo 'ERROR: Invalid application.' >&2; exit 2; }
log_dir=${BUILD_LOG_DIR:-$ROOT/.build-logs}
mkdir -p "$log_dir"
log_dir=$(cd -- "$log_dir" && pwd)
export BUILD_LOG_DIR="$log_dir"
report="$log_dir/diagnose-$app.log"
{
  echo "UTC: $(date -u +%FT%TZ)"
  echo "Application: $app"
  echo "Repository: $ROOT"
  echo "ANDROID_HOME=${ANDROID_HOME:-unset}"
  echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-unset}"
  echo "JAVA_HOME=${JAVA_HOME:-unset}"
  # check-env also checks ADB; a missing device-tool must not block compilation.
  set +e
  bash "$ROOT/scripts/check-env.sh"
  env_status=$?
  echo "ENV_CHECK_EXIT=$env_status (informational; ADB not needed to compile)"
  set -e
} > "$report" 2>&1
set +e
bash "$ROOT/scripts/build-apk.sh" "$app" debug 2>&1 | tee -a "$report"
result=${PIPESTATUS[0]}
set -e
{
  echo "BUILD_EXIT=$result"
  echo 'APK output inventory (not proof of a fresh successful build):'
  apps=("$app"); [[ $app != all ]] || apps=(marketer orders-delivery)
  for name in "${apps[@]}"; do
    output="$ROOT/apps/$name/app/build/outputs"
    if [[ -d $output ]]; then
      find "$output" -type f \( -name '*.apk' -o -name 'output-metadata.json' \) -print
    else
      echo "Output directory missing: $output"
    fi
  done
  echo 'Upload this directory as an artifact using if: always(); do not replace missing APKs with placeholder text.'
  echo "Diagnostics: $log_dir"
} | tee -a "$report"
printf '%s\n' "$result" > "$log_dir/diagnose-$app.exit-code"
exit "$result"
