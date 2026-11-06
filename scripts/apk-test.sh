#!/usr/bin/env bash
#
# apk-test.sh — اختبار وتجهيز ملفات APK في مستودع TAMMTOOL
#
# الإصدار: 2.0 — "اختبر على جهازك، حتى بدون هاتف"
#
# نوعا الفحص:
#   • فحص ثابت (لا يحتاج جهازاً): validate / info
#     بنية APK، الحزمة، الإصدار، minSdk/targetSdk، الأذونات، التوقيع، الحجم.
#   • فحص حيّ (يحتاج هاتفاً أو محاكياً): install / launch / logcat / screenshot / test
#     تثبيت، تشغيل، تأكيد أن التطبيق لم ينهر، لقطة شاشة، وتقرير في test-reports/.
#
# الاستخدام:
#   ./scripts/apk-test.sh <أمر> [وسيط] [خيارات]
#
# أمثلة:
#   ./scripts/apk-test.sh validate --app marketer       # بدون جهاز
#   ./scripts/apk-test.sh test --app marketer --reinstall
#   ./scripts/apk-test.sh info dist/marketer-debug-v1.0.0-abcd123.apk
#   ./scripts/apk-test.sh devices
#   ./scripts/apk-test.sh connect 192.168.1.20:5555
#   ./scripts/apk-test.sh emulator --create
#   ./scripts/apk-test.sh doctor
#
# متغيرات بيئة مدعومة:
#   ANDROID_HOME / ANDROID_SDK_ROOT   للعثور على adb و aapt2 و apksigner و emulator
#   TAMM_ANDROID_SDK                  مسار SDK (بديل ANDROID_HOME)
#   TAMM_ADB                          مسار adb يدوياً
#   TAMM_APK                          مسار APK الافتراضي
#   TAMM_ADB_SERIAL                   رقم الجهاز الافتراضي
#   TAMM_TEST_TIMEOUT                 مهلة التشغيل بالثواني (افتراضي 25)
#   TAMM_AVD                          اسم المحاكي (افتراضي tamm_avd)
#   NO_COLOR                          تعطيل الألوان
#
# رموز الخروج:
#   0 نجاح · 1 خطأ استخدام/بيئة · 2 فشل التثبيت · 3 فشل التشغيل · 4 انهيار/ANR · 5 لا يوجد جهاز
#
set -euo pipefail

VERSION="2.0.0"

# ============================================================
# المسارات والإعدادات
# ============================================================
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

COMMAND=""
ARG1=""
APK_FILE="${TAMM_APK:-}"
APP_NAME=""
APP_DIR_FOUND=""
PKG=""
SERIAL="${TAMM_ADB_SERIAL:-}"
TIMEOUT="${TAMM_TEST_TIMEOUT:-25}"
OUT_DIR="$PROJECT_ROOT/test-reports"
SCREENSHOT_DIR="$PROJECT_ROOT/screenshots"
SDK_DIR="${TAMM_ANDROID_SDK:-}"
AVD_NAME="${TAMM_AVD:-tamm_avd}"
OPT_NO_LAUNCH=0
OPT_NO_LOGCAT=0
OPT_NO_SCREENSHOT=0
OPT_REINSTALL=0
OPT_GRANT=0
OPT_DOWNGRADE=0
OPT_FOLLOW=0
OPT_CREATE_AVD=0
OPT_DRY_RUN=0
OPT_JSON=0
OPT_VERBOSE=0
OPT_ASSUME_YES="${TAMM_YES:-0}"

ADB_BIN=""
BADGE=""
REPORT_FILE=""
declare -a ADB_ARR=()

# ============================================================
# الألوان
# ============================================================
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  C_RED=$'\033[0;31m'
  C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[1;33m'
  C_BLUE=$'\033[0;34m'
  C_BOLD=$'\033[1m'
  C_NC=$'\033[0m'
else
  C_RED=''
  C_GREEN=''
  C_YELLOW=''
  C_BLUE=''
  C_BOLD=''
  C_NC=''
fi

log_info() { printf '%s\n' "${C_BLUE}[i]${C_NC} $*"; }
log_ok() { printf '%s\n' "${C_GREEN}[✓]${C_NC} $*"; }
log_warn() { printf '%s\n' "${C_YELLOW}[!]${C_NC} $*" >&2; }
log_err() { printf '%s\n' "${C_RED}[✗]${C_NC} $*" >&2; }
log_step() { printf '\n%s\n' "${C_BOLD}== $* ==${C_NC}"; }

die() {
  log_err "$*"
  exit 1
}
die_usage() {
  log_err "$*"
  echo >&2
  usage >&2
  exit 1
}

confirm() {
  local prompt="$1" answer=""
  [[ "$OPT_ASSUME_YES" == "1" ]] && return 0
  if [[ ! -t 0 ]]; then
    log_warn "$prompt — تم الرد بـ (لا) لعدم وجود تفاعل. أضف --yes للتنفيذ التلقائي."
    return 1
  fi
  printf '%s [y/N] ' "$prompt"
  IFS= read -r answer || answer=""
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
    y | yes | "ن" | "نعم") return 0 ;;
    *) return 1 ;;
  esac
}

# ============================================================
# عدّادات نتائج الاختبار
# ============================================================
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0
FAILURES_TEXT=""

pass() {
  log_ok "$*"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
}
fail() {
  log_err "$*"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
  FAILURES_TEXT="${FAILURES_TEXT}$*
"
}
warn() {
  log_warn "$*"
  CHECKS_WARNED=$((CHECKS_WARNED + 1))
}

# تنفيذ أمر مع احترام --dry-run
run() {
  printf '%s\n' "${C_BLUE}\$${C_NC} $*"
  [[ "$OPT_DRY_RUN" == "1" ]] && return 0
  "$@"
}

# ============================================================
# المساعدة
# ============================================================
usage() {
  cat <<'HELP'
=============================================
  TAMMTOOL — اختبار ملفات APK (محلياً)
=============================================

الاستخدام:
  ./scripts/apk-test.sh <أمر> [وسيط] [خيارات]

أوامر لا تحتاج جهازاً (تعمل على أي لابتوب):
  info [apk]            معلومات APK: الحزمة، الإصدار، SDK، الأذونات، التوقيع
  validate [apk]        فحص ثابت كامل (بنية + توقيع + أحجام) — مناسب لـ CI
  devices               عرض الأجهزة المتصلة عبر adb
  doctor                تشخيص: adb, SDK, aapt2, apksigner, الأجهزة، المحاكي
  emulator              حالة المحاكي ( --create ينشئ AVD عبر sdkmanager )
  selftest              اختبار السكربتات نفسها (لا يحتاج أدوات Android)

أوامر تحتاج هاتفاً أو محاكياً:
  install [apk]         تثبيت (--reinstall --grant --allow-downgrade)
  launch <package>      تشغيل التطبيق
  logcat <package>      سجلات التطبيق (--follow للبث الحي)
  screenshot [file.png] لقطة شاشة
  uninstall <package>   إزالة التطبيق
  connect <ip:port>     ربط ADB عبر الشبكة (Wireless debugging)
  test [apk]            الاختبار الكامل: فحص + تثبيت + تشغيل + كشف انهيار + لقطة + تقرير

خيارات عامة:
  --app NAME            اسم التطبيق (للعثور على APK واسم الحزمة)
  --apk PATH            مسار ملف APK
  --package PKG         تجاوز اسم الحزمة المكتشف
  --serial ID           رقم الجهاز عند وجود أكثر من جهاز (adb -s)
  --sdk DIR             مسار Android SDK
  --timeout N           ثوانٍ الانتظار بعد التشغيل (افتراضي 25)
  --out DIR             مجلد التقارير (افتراضي ./test-reports)
  --screenshots DIR     مجلد اللقطات (افتراضي ./screenshots)
  --reinstall           إزالة ثم تثبيت (يحلّ INSTALL_FAILED_UPDATE_INCOMPATIBLE)
  --grant               منح الأذونات تلقائياً عند التثبيت (-g)
  --allow-downgrade     تثبيت نسخة أقدم (-d)
  --no-launch           تثبيت فقط دون التشغيل
  --no-logcat           تخطي فحص السجلات
  --no-screenshot       تخطي لقطة الشاشة
  --follow              في logcat: البث المستمر بدل عرض آخر سجلات
  --json                إخراج JSON في التقرير (للـ CI)
  --dry-run             طباعة الأوامر دون تنفيذ
  --yes, -y             القبول التلقائي
  --verbose, -v         تفاصيل أكثر
  --help, -h            هذه الرسالة
  --version             رقم الإصدار

أمثلة:
  # 1) بنيت APK للتو — افحصه بدون هاتف
  ./scripts/build-apk.sh debug marketer
  ./scripts/apk-test.sh validate --app marketer

  # 2) هاتف موصول بالـ USB
  ./scripts/apk-test.sh test --app marketer --reinstall

  # 3) لا هاتف: استخدم محاكياً محلياً
  ./scripts/apk-test.sh emulator --create
  ~/android-sdk/emulator/emulator -avd tamm_avd -no-window -no-audio &
  ./scripts/apk-test.sh test --app marketer
HELP
}

# ============================================================
# تحليل الوسائط
# ============================================================
parse_args() {
  local -a positional=()
  if [[ $# -gt 0 && "$1" != -* ]]; then
    COMMAND="$1"
    shift
  else
    COMMAND=""
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      --version)
        printf 'apk-test.sh v%s\n' "$VERSION"
        exit 0
        ;;
      --app)
        [[ $# -ge 2 ]] || die "--app يحتاج قيمة"
        APP_NAME="$2"
        shift
        ;;
      --app=*) APP_NAME="${1#*=}" ;;
      --apk)
        [[ $# -ge 2 ]] || die "--apk يحتاج مساراً"
        APK_FILE="$2"
        shift
        ;;
      --apk=*) APK_FILE="${1#*=}" ;;
      --package)
        [[ $# -ge 2 ]] || die "--package يحتاج قيمة"
        PKG="$2"
        shift
        ;;
      --package=*) PKG="${1#*=}" ;;
      --serial)
        [[ $# -ge 2 ]] || die "--serial يحتاج قيمة"
        SERIAL="$2"
        shift
        ;;
      --serial=*) SERIAL="${1#*=}" ;;
      --sdk)
        [[ $# -ge 2 ]] || die "--sdk يحتاج مساراً"
        SDK_DIR="$2"
        shift
        ;;
      --sdk=*) SDK_DIR="${1#*=}" ;;
      --timeout)
        [[ $# -ge 2 ]] || die "--timeout يحتاج رقماً"
        TIMEOUT="$2"
        shift
        ;;
      --timeout=*) TIMEOUT="${1#*=}" ;;
      --out)
        [[ $# -ge 2 ]] || die "--out يحتاج مساراً"
        OUT_DIR="$2"
        shift
        ;;
      --out=*) OUT_DIR="${1#*=}" ;;
      --screenshots)
        [[ $# -ge 2 ]] || die "--screenshots يحتاج مساراً"
        SCREENSHOT_DIR="$2"
        shift
        ;;
      --screenshots=*) SCREENSHOT_DIR="${1#*=}" ;;
      --reinstall) OPT_REINSTALL=1 ;;
      --grant) OPT_GRANT=1 ;;
      --allow-downgrade) OPT_DOWNGRADE=1 ;;
      --no-launch) OPT_NO_LAUNCH=1 ;;
      --no-logcat) OPT_NO_LOGCAT=1 ;;
      --no-screenshot) OPT_NO_SCREENSHOT=1 ;;
      --follow) OPT_FOLLOW=1 ;;
      --create) OPT_CREATE_AVD=1 ;;
      --json) OPT_JSON=1 ;;
      --dry-run) OPT_DRY_RUN=1 ;;
      --yes | -y) OPT_ASSUME_YES=1 ;;
      --verbose | -v) OPT_VERBOSE=1 ;;
      --no-color) NO_COLOR=1 ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          positional+=("$1")
          shift
        done
        break
        ;;
      -*) die_usage "خيار غير معروف: $1" ;;
      *) positional+=("$1") ;;
    esac
    shift
  done

  [[ -n "$COMMAND" ]] || COMMAND="help"
  case "${#positional[@]}" in
    0) ARG1="" ;;
    *) ARG1="${positional[0]}" ;;
  esac

  if [[ ! "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    die "--timeout يجب أن يكون رقماً بالثواني (مثال: --timeout 40)"
  fi

  # توافق مع الاستخدام القديم: <أمر> <وسيط>
  case "$COMMAND" in
    info | validate | check | install | test | smoke)
      if [[ -n "$ARG1" && -z "$APK_FILE" ]]; then
        case "$ARG1" in
          *.apk | *.aab) APK_FILE="$ARG1" ;;
          */) APK_FILE="${ARG1%/}" ;;
          *)
            if [[ -z "$APP_NAME" ]]; then
              APP_NAME="$ARG1"
            fi
            ;;
        esac
      fi
      ;;
    launch | start | logcat | uninstall)
      [[ -n "$ARG1" && -z "$PKG" ]] && PKG="$ARG1"
      ;;
    connect)
      [[ -n "$ARG1" && -z "$CONNECT_TARGET" ]] && CONNECT_TARGET="$ARG1"
      ;;
  esac

  if [[ -n "$SERIAL" ]]; then
    ADB_ARR=()
  fi
}
CONNECT_TARGET=""

# ============================================================
# أدوات: SDK / adb / aapt
# ============================================================
sdk_candidates() {
  printf '%s\n' \
    "$SDK_DIR" \
    "${ANDROID_HOME:-}" \
    "${ANDROID_SDK_ROOT:-}" \
    "$PROJECT_ROOT/android-sdk" \
    "$HOME/android-sdk" \
    "$HOME/.android-sdk" \
    "$HOME/Android/Sdk" \
    "$HOME/Library/Android/sdk" \
    "/opt/android-sdk" \
    "/usr/lib/android-sdk"
}

first_sdk_dir() {
  local cand
  while IFS= read -r cand; do
    [[ -n "$cand" ]] || continue
    [[ -d "$cand" ]] || continue
    printf '%s\n' "$cand"
    return 0
  done < <(sdk_candidates)
  return 1
}

# يبحث في build-tools عن أداة (aapt2 / apksigner / zipalign)
find_build_tool() {
  local tool="$1" sdk cand best
  while IFS= read -r sdk; do
    [[ -d "$sdk/build-tools" ]] || continue
    best="$(ls -1d "$sdk/build-tools"/*/ 2>/dev/null | sort -V | tail -n 1 || true)"
    [[ -n "$best" && -x "${best}${tool}" ]] || continue
    printf '%s\n' "${best%/}/$tool"
    return 0
  done < <(sdk_candidates)
  return 1
}

tool_path() {
  # tool_path <اسم> — من PATH أولاً، ثم من SDK
  local tool="$1" found=""
  if command -v "$tool" >/dev/null 2>&1; then
    command -v "$tool"
    return 0
  fi
  case "$tool" in
    adb)
      while IFS= read -r found; do
        [[ -n "$found" ]] || continue
        if [[ -x "$found/platform-tools/adb" ]]; then
          printf '%s\n' "$found/platform-tools/adb"
          return 0
        fi
      done < <(sdk_candidates)
      ;;
    aapt | aapt2 | apksigner | zipalign)
      found="$(find_build_tool "$tool" || true)"
      [[ -n "$found" ]] && {
        printf '%s\n' "$found"
        return 0
      }
      ;;
    sdkmanager | avdmanager)
      while IFS= read -r found; do
        [[ -n "$found" ]] || continue
        local p
        for p in "$found/cmdline-tools/latest/bin/$tool" "$found/cmdline-tools/bin/$tool"; do
          if [[ -x "$p" ]]; then
            printf '%s\n' "$p"
            return 0
          fi
        done
      done < <(sdk_candidates)
      ;;
    emulator)
      while IFS= read -r found; do
        [[ -n "$found" ]] || continue
        if [[ -x "$found/emulator/emulator" ]]; then
          printf '%s\n' "$found/emulator/emulator"
          return 0
        fi
      done < <(sdk_candidates)
      ;;
    apkanalyzer)
      while IFS= read -r found; do
        [[ -n "$found" ]] || continue
        local p
        for p in "$found/cmdline-tools/latest/bin/apkanalyzer" "$found/tools/bin/apkanalyzer"; do
          if [[ -x "$p" ]]; then
            printf '%s\n' "$p"
            return 0
          fi
        done
      done < <(sdk_candidates)
      ;;
  esac
  return 1
}

resolve_adb() {
  [[ -n "$ADB_BIN" ]] && return 0
  if [[ -n "${TAMM_ADB:-}" ]]; then
    [[ -x "$TAMM_ADB" ]] || die "TAMM_ADB غير قابل للتنفيذ: $TAMM_ADB"
    ADB_BIN="$TAMM_ADB"
  else
    ADB_BIN="$(tool_path adb || true)"
  fi
  if [[ -z "$ADB_BIN" ]]; then
    log_err "لم أجد adb على هذا الجهاز."
    cat >&2 <<'ADBHELP'
  ثبّت Platform-Tools (لا تحتاج صلاحيات مدير):
    Linux :
      wget -O /tmp/pt.zip https://dl.google.com/android/repository/platform-tools-latest-linux.zip
      unzip -q -o /tmp/pt.zip -d "$HOME"
      export PATH="$HOME/platform-tools:$PATH"
    macOS : brew install android-platform-tools
    أو صدّر ANDROID_HOME إلى مجلد SDK الذي يحتوي platform-tools/adb
  أو جرّب الأوامر التي لا تحتاج جهازاً: ./scripts/apk-test.sh validate
ADBHELP
    return 1
  fi
  return 0
}

# يحدّث مصفوفة ADB_ARR بعد تعيين SERIAL
sync_adb_arr() {
  resolve_adb || return 1
  if [[ -n "$SERIAL" ]]; then
    ADB_ARR=("$ADB_BIN" -s "$SERIAL")
  else
    ADB_ARR=("$ADB_BIN")
  fi
  return 0
}

adb_devices_list() {
  resolve_adb || return 1
  "$ADB_BIN" devices 2>/dev/null | tail -n +2 | awk '$2=="device"{print $1}'
}

require_device() {
  resolve_adb || exit 1
  [[ "$OPT_DRY_RUN" == "1" ]] && {
    [[ -n "$SERIAL" ]] || SERIAL="dry-run-device"
    sync_adb_arr || return 0
    return 0
  }
  local -a list=()
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && list+=("$line")
  done < <(adb_devices_list)

  case "${#list[@]}" in
    0)
      log_err "لا يوجد جهاز متجهز عبر adb."
      cat >&2 <<'DEVHELP'
  جرّب التالي بالترتيب:
    1) وصّل الهاتف بكابل USB، فعّل "خيارات المطوّر" ثم "تصحيح USB".
    2) شغّل: adb devices — يجب أن تظهر الحالة device (لا unauthorized).
       إذا كانت unauthorized: اقبل نافذة "Allow USB debugging" في الهاتف.
       إذا كانت offline: adb kill-server && adb devices
    3) لا هاتف عندك؟ أنشئ محاكياً: ./scripts/apk-test.sh emulator --create
    4) أو اكتفِ بالفحص الثابت الذي لا يحتاج جهازاً: ./scripts/apk-test.sh validate
    5) للتشخيص الكامل: ./scripts/apk-test.sh doctor
DEVHELP
      "$ADB_BIN" devices >&2 || true
      exit 5
      ;;
    1)
      [[ -n "$SERIAL" ]] || SERIAL="${list[0]}"
      ;;
    *)
      if [[ -z "$SERIAL" ]]; then
        log_err "يوجد أكثر من جهاز متجهز — حدّد واحداً بـ --serial."
        printf '  الأجهزة: %s\n' "${list[*]}" >&2
        printf '  مثال: ./scripts/apk-test.sh test --serial %s\n' "${list[0]}" >&2
        exit 1
      fi
      ;;
  esac
  log_info "الجهاز: $SERIAL"
  sync_adb_arr || exit 1
  return 0
}

# ============================================================
# العثور على APK واستخراج معلوماته
# ============================================================
discover_apk() {
  if [[ -n "$APK_FILE" ]]; then
    [[ -f "$APK_FILE" ]] || die "ملف APK غير موجود: $APK_FILE"
    return 0
  fi
  APP_DIR_FOUND=""
  local base
  for base in "$PROJECT_ROOT/apps" "$PROJECT_ROOT/examples" "$PROJECT_ROOT/projects" "$PROJECT_ROOT/templates"; do
    if [[ -n "$APP_NAME" && -d "$base/$APP_NAME" ]]; then
      APP_DIR_FOUND="$base/$APP_NAME"
      break
    fi
  done

  local -a candidates=()
  local line
  if [[ -d "$PROJECT_ROOT/dist" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && candidates+=("$line")
    done < <(
      ls -1t "$PROJECT_ROOT"/dist/*.apk 2>/dev/null | {
        if [[ -n "$APP_NAME" ]]; then
          grep -F -- "$APP_NAME" || true
        else
          cat
        fi
      }
    )
  fi

  if [[ ${#candidates[@]} -eq 0 && -n "$APP_DIR_FOUND" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && candidates+=("$line")
    done < <(
      find "$APP_DIR_FOUND" -path '*/outputs/apk/*' -name '*.apk' -printf '%T@ %p\n' 2>/dev/null |
        sort -rn | cut -d' ' -f2-
    )
    # أنظمة لا تدعم find -printf (macOS)
    if [[ ${#candidates[@]} -eq 0 ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] && candidates+=("$line")
      done < <(find "$APP_DIR_FOUND" -path '*/outputs/apk/*' -name '*.apk' 2>/dev/null)
    fi
  fi

  if [[ ${#candidates[@]} -gt 0 ]]; then
    APK_FILE="${candidates[0]}"
    log_info "آخر APK مبني: $APK_FILE"
    return 0
  fi

  log_err "لم أجد ملف APK لاختباره."
  printf '  ابنِه أولاً:   ./scripts/build-apk.sh debug %s\n' "${APP_NAME:-marketer}" >&2
  printf '  أو حدّد المسار: ./scripts/apk-test.sh %s --apk path/to/app.apk\n' "${COMMAND:-info}" >&2
  return 1
}

apk_required() {
  discover_apk || exit 1
  [[ "$OPT_DRY_RUN" == "1" && ! -e "$APK_FILE" ]] && return 0
  [[ -f "$APK_FILE" ]] || die "ملف APK غير موجود: $APK_FILE"
  [[ -s "$APK_FILE" ]] || die "ملف APK فارغ أو تالف: $APK_FILE"
  return 0
}

detect_badge_tool() {
  [[ -n "$BADGE" ]] && return 0
  local t
  for t in aapt2 aapt apkanalyzer; do
    local p=""
    p="$(tool_path "$t" || true)"
    if [[ -n "$p" ]]; then
      BADGE="$t:$p"
      return 0
    fi
  done
  BADGE="python"
  return 0
}

badge_dump() {
  detect_badge_tool
  local kind="${BADGE%%:*}" tool="${BADGE#*:}"
  [[ "$BADGE" == "python" ]] && return 1
  case "$kind" in
    aapt2 | aapt) "$tool" dump badging "$APK_FILE" 2>/dev/null ;;
    apkanalyzer) "$tool" manifest print "$APK_FILE" 2>/dev/null ;;
  esac
}

# badge_field <مفتاح> — يقرأ حقول aapt/aapt2/apkanalyzer بصيغهم المختلفة
#   aapt2 : package: name='com.x' versionCode='1' versionName='1.0.0'
#           sdkVersion:'24'   targetSdkVersion:'35'
#   apkanalyzer: android:package="com.x" android:versionName="1.0.0"
badge_field() {
  local key="$1" dump="" val=""
  dump="$(badge_dump 2>/dev/null | tr -d '\r')" || true
  [[ -n "$dump" ]] || return 1
  if [[ "$key" == "package" ]]; then
    val="$(printf '%s\n' "$dump" | sed -n "s/^[[:space:]]*package:[[:space:]]*name='\([^']*\)'.*/\1/p" | head -n 1)"
    [[ -n "$val" ]] || val="$(printf '%s\n' "$dump" | sed -n 's/.*package="\([^"]*\)".*/\1/p' | head -n 1)"
  else
    val="$(printf '%s\n' "$dump" | sed -n "s/.*${key}='\([^']*\)'.*/\1/p" | head -n 1)"
    [[ -n "$val" ]] || val="$(printf '%s\n' "$dump" | sed -n "s/.*${key}=\"\([^\"]*\)\".*/\1/p" | head -n 1)"
  fi
  [[ -n "$val" ]] || return 1
  printf '%s\n' "$val"
}

# استخراج احتياطي بدون أدوات Android (تحليل AndroidManifest.xml الثنائي)
python_manifest_scan() {
  command -v python3 >/dev/null 2>&1 || return 1
  APK_PATH="$APK_FILE" python3 - <<'PY'
import os, re, sys, zipfile
path = os.environ["APK_PATH"]
try:
    with zipfile.ZipFile(path) as z:
        raw = z.read("AndroidManifest.xml")
except Exception:
    sys.exit(1)

cands = []
try:
    txt = raw.decode("utf-16-le", errors="ignore")
    cands += re.findall(r"[\x20-\x7e]{4,}", txt)
except Exception:
    pass
try:
    cands += re.findall(r"[A-Za-z_][\w.$]{3,}", raw.decode("latin-1", errors="ignore"))
except Exception:
    pass

pkg_re = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-zA-Z_$][A-Za-z0-9_$]*){1,}$")
pkgs = [c for c in cands if pkg_re.match(c) and not c.startswith("android.") and "android.permission" not in c]
if pkgs:
    best = sorted(set(pkgs), key=lambda p: (pkgs.count(p), len(p)))[-1]
    print("package=" + best)
seen = []
for c in cands:
    if c.startswith("permission.") or c.startswith("android.permission."):
        if c not in seen:
            seen.append(c)
for s in sorted(seen)[:20]:
    print("perm=" + s)
PY
}

resolve_package() {
  [[ -n "$PKG" ]] && return 0
  local p=""
  p="$(badge_field package || true)"
  if [[ -z "$p" ]]; then
    p="$(python_manifest_scan 2>/dev/null | sed -n 's/^package=//p' | head -n 1)" || true
    [[ -n "$p" ]] && log_warn "اسم الحزمة مستخرج بتحليل Manifest (بدون aapt) — إن كان خاطئاً استخدم --package."
  fi
  if [[ -z "$p" && -n "$APP_DIR_FOUND" ]]; then
    local gf
    for gf in "$APP_DIR_FOUND/app/build.gradle.kts" "$APP_DIR_FOUND/app/build.gradle" "$APP_DIR_FOUND/build.gradle.kts"; do
      [[ -f "$gf" ]] || continue
      p="$(sed -n 's/.*applicationId[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$gf" | head -n 1)"
      [[ -n "$p" ]] || p="$(sed -n 's/.*applicationId[[:space:]]*"\([^"]*\)".*/\1/p' "$gf" | head -n 1)"
      [[ -n "$p" ]] && break
    done
    [[ -n "$p" ]] && log_info "اسم الحزمة من build.gradle: $p"
  fi
  [[ -n "$p" ]] || {
    log_err "تعذّر استخراج اسم الحزمة من الـ APK."
    printf '  حدّده يدوياً: ./scripts/apk-test.sh %s --package com.tammtool.marketerapp\n' "${COMMAND:-test}" >&2
    return 1
  }
  PKG="$p"
  return 0
}

sha256_of() {
  local f="${1:-}"
  [[ -n "$f" && -f "$f" ]] || {
    printf 'غير متاح\n'
    return
  }
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | cut -d' ' -f1
  else
    printf 'غير متاح\n'
  fi
}

human_size() {
  local f="${1:-}" bytes=""
  [[ -n "$f" && -e "$f" ]] || {
    printf 'غير متاح\n'
    return
  }
  bytes="$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f" 2>/dev/null || echo 0)"
  case "$bytes" in
    '' | 0)
      printf 'غير متاح\n'
      return
      ;;
  esac
  awk -v b="$bytes" 'BEGIN{s="B KB MB GB";split(s,u," ");o=b;i=1;while(b>=1024&&i<4){b/=1024;i++}printf "%.1f %s (%d bytes)", b, u[i], o}'
}

zip_entries() {
  if command -v unzip >/dev/null 2>&1; then
    unzip -Z1 "$1" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys,zipfile;print("\n".join(zipfile.ZipFile(sys.argv[1]).namelist()))' "$1" 2>/dev/null
  else
    return 1
  fi
}

mark() {
  if [[ -n "$(tool_path "$1" 2>/dev/null || true)" ]]; then
    printf '✓'
  else
    printf '✗'
  fi
}

# ============================================================
# info
# ============================================================
cmd_info() {
  apk_required
  detect_badge_tool
  echo "============================================="
  printf '  معلومات ملف APK\n'
  echo "============================================="
  printf '  الملف      : %s\n' "$APK_FILE"
  printf '  الحجم      : %s\n' "$(human_size "$APK_FILE")"
  printf '  آخر تعديل  : %s\n' "$(date -r "$APK_FILE" '+%Y-%m-%d %H:%M' 2>/dev/null || printf 'غير متاح\n')"
  printf '  SHA-256    : %s\n' "$(sha256_of "$APK_FILE")"
  echo

  if [[ "$BADGE" == "python" ]]; then
    log_warn "لا يوجد aapt2/aapt/apkanalyzer — استخدام تحليل احتياطي (دقة أقل)."
    python_manifest_scan || warn "تعذّر تحليل AndroidManifest.xml"
  else
    badge_dump |
      grep -E '^package:|^application-label:|^sdkVersion:|^targetSdkVersion:|^launchable-activity:|^uses-permission' |
      head -n 30 | sed 's/^/  /' || true
  fi

  echo
  printf '  الأرشيف    : %s ملف، أكبرها:\n' "$(zip_entries "$APK_FILE" 2>/dev/null | grep -c . || printf 'غير متاح')"
  if command -v unzip >/dev/null 2>&1; then
    unzip -l "$APK_FILE" 2>/dev/null | awk 'NR>3 && $1+0>0 {print $1, $4}' | sort -rn | head -n 5 |
      awk '{printf "    %9.1f KB  %s\n", $1/1024, $2}'
  fi
  echo
  printf '  الأدوات المتاحة: aapt2=%s  aapt=%s  apksigner=%s  adb=%s\n' \
    "$(mark aapt2)" "$(mark aapt)" "$(mark apksigner)" "$(mark adb)"
}

# ============================================================
# validate — فحص ثابت بدون جهاز
# ============================================================
cmd_validate() {
  apk_required
  detect_badge_tool
  log_step "فحص ثابت لملف APK (لا يحتاج جهازاً)"
  printf '  الملف: %s (%s)\n' "$APK_FILE" "$(human_size "$APK_FILE")"
  echo

  # 1) سلامة الأرشيف
  if command -v unzip >/dev/null 2>&1; then
    if unzip -tq "$APK_FILE" >/dev/null 2>&1; then
      pass "أرشيف APK سليم (unzip -t)"
    else
      fail "أرشيف APK تالف — أعد البناء أو التنزيل."
    fi
  elif python3 -c 'import sys,zipfile;sys.exit(0 if zipfile.ZipFile(sys.argv[1]).testzip() in (None,) else 1)' "$APK_FILE" 2>/dev/null; then
    pass "أرشيف APK سليم (python zipfile)"
  else
    warn "لا unzip ولا python3 متاحان للتحقق من الأرشيف."
  fi

  # 2) الملفات الإلزامية
  local entries=""
  entries="$(zip_entries "$APK_FILE" || printf '')"
  if [[ -z "$entries" ]]; then
    fail "تعذّر قراءة محتويات APK."
  else
    if printf '%s\n' "$entries" | grep -qx 'AndroidManifest.xml'; then
      pass "AndroidManifest.xml موجود"
    else
      fail "AndroidManifest.xml مفقود — ملف غير صالح."
    fi
    if printf '%s\n' "$entries" | grep -qE '^classes[0-9]*\.dex$'; then
      pass "classes.dex موجود ($(printf '%s\n' "$entries" | grep -cE '^classes[0-9]*\.dex$') ملف dex)"
    else
      fail "لا يوجد classes.dex — الكود غير مُضمَّن."
    fi
    if printf '%s\n' "$entries" | grep -qx 'resources.arsc'; then
      pass "resources.arsc موجود"
    else
      warn "resources.arsc غير موجود (غير معتاد في تطبيق واجهة كامل)."
    fi
  fi

  # 3) الحزمة والإصدارات
  local pkg="" vname="" vcode="" minsdk="" targetsdk=""
  pkg="$(badge_field package || true)"
  if [[ -z "$pkg" ]]; then
    pkg="$(python_manifest_scan 2>/dev/null | sed -n 's/^package=//p' | head -n 1)" || true
    [[ -n "$pkg" ]] && warn "اسم الحزمة من تحليل Manifest (بدون aapt)."
  fi
  vname="$(badge_field versionName || true)"
  vcode="$(badge_field versionCode || true)"
  minsdk="$(badge_field minSdkVersion || true)"
  targetsdk="$(badge_field targetSdkVersion || true)"

  if [[ -n "$pkg" ]]; then
    pass "اسم الحزمة: $pkg"
    [[ -z "$PKG" ]] && PKG="$pkg"
  else
    fail "تعذّر قراءة اسم الحزمة."
  fi
  printf '  versionName : %s\n' "${vname:-غير متاح}"
  printf '  versionCode : %s\n' "${vcode:-غير متاح}"
  printf '  minSdk      : %s\n' "${minsdk:-غير متاح}"
  printf '  targetSdk   : %s\n' "${targetsdk:-غير متاح}"
  [[ "$minsdk" =~ ^[0-9]+$ ]] && [[ "$minsdk" -gt 24 ]] &&
    warn "minSdk=$minsdk: هواتف Android 6/7 (API 23-24) لن تثبّت هذا التطبيق."
  [[ "$targetsdk" =~ ^[0-9]+$ ]] && [[ "$targetsdk" -lt 34 ]] &&
    warn "targetSdk=$targetsdk: متجر Play يطلب targetSdk ≥ 34 للتحديثات الجديدة."

  # 4) التوقيع
  local signer=""
  signer="$(tool_path apksigner || true)"
  if [[ -n "$signer" ]]; then
    if "$signer" verify "$APK_FILE" >/dev/null 2>&1; then
      pass "التوقيع صالح (apksigner verify)"
      "$signer" verify --print-certs "$APK_FILE" 2>/dev/null |
        grep -E 'certificate (DN|SHA-256) digest' | sed 's/^/    /' || true
    elif [[ "$(basename "$APK_FILE")" == *unsigned* ]]; then
      fail "الملف غير موقّع ($(basename "$APK_FILE")) — لن يُثبَّت على جهاز. استخدم scripts/sign-apk.sh"
    else
      fail "فشل التحقق من التوقيع — التطبيق لن يُثبَّت على الجهاز."
    fi
  else
    if printf '%s\n' "$entries" | grep -qE '^META-INF/.*\.(RSA|DSA|EC)$'; then
      pass "يوجد توقيع v1 في META-INF (apksigner غير مثبت للتحقق الكامل)."
    else
      fail "لا يوجد توقيع في META-INF ولا apksigner للتحقق — وقّع APK قبل الاختبار الحيّ."
    fi
  fi

  # 5) تحذيرات مفيدة
  if [[ "$(basename "$APK_FILE")" == *debug* ]]; then
    log_info "هذا build debug: يعمل على أي جهاز بdebuggable، ولا يُرفع للمتجر."
  fi

  echo
  if [[ "$CHECKS_FAILED" -gt 0 ]]; then
    log_err "نتيجة الفحص الثابت: $CHECKS_FAILED مشكلة، $CHECKS_PASSED فحص ناجح."
    printf '%s' "$FAILURES_TEXT" | sed '/^$/d; s/^/  ✗ /' >&2
    return 4
  fi
  log_ok "الفحص الثابت سليم: $CHECKS_PASSED فحوص ناجحة، $CHECKS_WARNED تحذير."
  return 0
}

# ============================================================
# install
# ============================================================
cmd_install() {
  apk_required
  require_device
  log_step "تثبيت APK"
  printf '  الملف : %s\n' "$APK_FILE"
  printf '  الجهاز: %s\n' "$SERIAL"

  local -a flags=(-r)
  [[ "$OPT_GRANT" == "1" ]] && flags+=(-g)
  [[ "$OPT_DOWNGRADE" == "1" ]] && flags+=(-d)

  if [[ "$OPT_REINSTALL" == "1" ]]; then
    resolve_package || exit 1
    log_info "إزالة النسخة السابقة: $PKG"
    "${ADB_ARR[@]}" uninstall "$PKG" >/dev/null 2>&1 || true
  fi

  local out="" status=0
  out="$("${ADB_ARR[@]}" install "${flags[@]}" "$APK_FILE" 2>&1)" || status=$?
  printf '%s\n' "$out" | sed 's/^/  /'

  if [[ $status -ne 0 || "$out" == *Failure* ]]; then
    case "$out" in
      *INSTALL_FAILED_UPDATE_INCOMPATIBLE*)
        log_warn "النسخة المثبتة موقّعة بمفتاح مختلف (شائع بين debug/release)."
        resolve_package || true
        printf '  الحل: ./scripts/apk-test.sh install --reinstall --apk %s\n' "$APK_FILE" >&2
        if confirm "إزالة ${PKG:-التطبيق} وإعادة التثبيت الآن؟"; then
          "${ADB_ARR[@]}" uninstall "$PKG" >/dev/null 2>&1 || true
          out="$("${ADB_ARR[@]}" install "${flags[@]}" "$APK_FILE" 2>&1)" || status=$?
          printf '%s\n' "$out" | sed 's/^/  /'
          [[ $status -eq 0 && "$out" != *Failure* ]] || {
            fail "ما زال التثبيت فاشلاً."
            exit 2
          }
        else
          exit 2
        fi
        ;;
      *INSTALL_FAILED_OLDER_SDK*)
        fail "أندرويد الجهاز أقدم من minSdk المطلوب في الـ APK."
        exit 2
        ;;
      *INSTALL_FAILED_INSUFFICIENT_STORAGE*)
        fail "مساحة الجهاز غير كافية لحذف/تثبيت التطبيق."
        exit 2
        ;;
      *INSTALL_FAILED_VERSION_DOWNGRADE*)
        fail "النسخة المثبتة أحدث — استخدم --allow-downgrade أو أعد التثبيت بـ --reinstall."
        exit 2
        ;;
      *PERMISSION_DENIED* | *"not found"* | *offline* | *unauthorized*)
        fail "adb لا يستطيع الوصول للجهاز: اقبل نافذة تصحيح USB على الهاتف ثم أعد المحاولة."
        exit 2
        ;;
      *)
        fail "فشل التثبيت (رمز adb: $status)."
        exit 2
        ;;
    esac
  fi
  pass "تم التثبيت على $SERIAL"
  resolve_package || true
  echo
  printf '  للتشغيل: ./scripts/apk-test.sh launch %s\n' "${PKG:-<package>}"
  return 0
}

# ============================================================
# launch
# ============================================================
cmd_launch() {
  require_device
  resolve_package || exit 1
  log_step "تشغيل $PKG"
  local activity=""
  activity="$("${ADB_ARR[@]}" shell cmd package resolve-activity --brief "$PKG" 2>/dev/null | tail -n 1 | tr -d '\r')" || true
  case "$activity" in
    *"$PKG"*)
      log_info "النشاط الرئيسي: $activity"
      run "${ADB_ARR[@]}" shell am start -W -n "$activity"
      ;;
    *)
      log_warn "تعذّر حلّ النشاط الرئيسي تلقائياً — استخدام monkey."
      run "${ADB_ARR[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
      ;;
  esac
  sleep 2
  local pid=""
  pid="$("${ADB_ARR[@]}" shell pidof "$PKG" 2>/dev/null | tr -d '\r\n' | awk '{print $1}')" || true
  if [[ -n "$pid" ]]; then
    pass "التطبيق يعمل (pid=$pid)"
  else
    warn "لم يُتأكد أن التطبيق يعمل — راجع: ./scripts/apk-test.sh logcat $PKG"
  fi
}

# ============================================================
# uninstall
# ============================================================
cmd_uninstall() {
  require_device
  if [[ -z "$PKG" ]]; then
    if [[ -n "$APK_FILE" || -n "$APP_NAME" ]]; then
      discover_apk >/dev/null 2>&1 || true
    fi
    resolve_package || {
      log_err "حدّد اسم الحزمة: ./scripts/apk-test.sh uninstall com.tammtool.marketerapp"
      exit 1
    }
  fi
  log_step "إزالة $PKG"
  if run "${ADB_ARR[@]}" uninstall "$PKG"; then
    pass "أُزيل التطبيق."
  else
    warn "فشلت الإزالة (قد لا يكون التطبيق مثبتاً أصلاً)."
  fi
}

# ============================================================
# logcat
# ============================================================
cmd_logcat() {
  require_device
  resolve_package || exit 1
  log_step "سجلات $PKG"
  local pid="" attempt=1
  while [[ $attempt -le 5 ]]; do
    pid="$("${ADB_ARR[@]}" shell pidof "$PKG" 2>/dev/null | tr -d '\r\n' | awk '{print $1}')" || true
    [[ -n "$pid" ]] && break
    sleep 1
    attempt=$((attempt + 1))
  done

  if [[ "$OPT_FOLLOW" == "1" ]]; then
    log_info "بثّ السجلات مباشرة (Ctrl+C للإيقاف)…"
    if [[ -n "$pid" ]]; then
      exec "${ADB_ARR[@]}" logcat --pid="$pid" -v time
    else
      log_warn "التطبيق لا يعمل — سأعرض كل السجلات."
      exec "${ADB_ARR[@]}" logcat -v time
    fi
  fi

  local file
  file="$OUT_DIR/$(date +%Y%m%d-%H%M%S)-logcat.txt"
  mkdir -p "$OUT_DIR" 2>/dev/null || true
  local -a flt=()
  [[ -n "$pid" ]] && flt=(--pid="$pid")
  "${ADB_ARR[@]}" logcat -d -v time "${flt[@]}" 2>/dev/null >"$file" || die "تعذّر قراءة logcat"
  local lines=""
  lines="$(grep -c . "$file" 2>/dev/null || printf '0')"
  log_ok "حُفظت السجلات: $file ($lines سطر)"
  echo
  printf '  %s أخطاء/انهيارات ذات صلة:\n' "$C_BOLD"
  grep -E 'E [Aa]ndroidRuntime|FATAL|ANR |Exception' "$file" | tail -n 30 | sed 's/^/    /' ||
    printf '    لا يوجد — يبدو أن التطبيق لم ينهر.\n'
  return 0
}

# ============================================================
# screenshot
# ============================================================
cmd_screenshot() {
  require_device
  local out="$ARG1"
  if [[ -z "$out" ]]; then
    mkdir -p "$SCREENSHOT_DIR" 2>/dev/null || true
    out="$SCREENSHOT_DIR/$(date +%Y%m%d-%H%M%S)-$(printf '%s' "${SERIAL:-device}" | tr -c 'A-Za-z0-9._-' '_').png"
  fi
  log_step "لقطة شاشة"
  if [[ "$OPT_DRY_RUN" == "1" ]]; then
    printf '%s\n' "${C_BLUE}\$${C_NC} ${ADB_ARR[*]:-adb} exec-out screencap -p > $out"
    return 0
  fi
  mkdir -p "$(dirname "$out")" 2>/dev/null || true
  if "${ADB_ARR[@]}" exec-out screencap -p >"$out" 2>/dev/null && [[ -s "$out" ]]; then
    :
  else
    log_warn "exec-out فشل — تجربة screencap ثم pull."
    "${ADB_ARR[@]}" shell screencap -p /sdcard/tamm-screenshot.png 2>/dev/null || true
    "${ADB_ARR[@]}" pull /sdcard/tamm-screenshot.png "$out" 2>/dev/null || true
    "${ADB_ARR[@]}" shell rm -f /sdcard/tamm-screenshot.png 2>/dev/null || true
  fi
  if [[ -s "$out" ]]; then
    pass "حُفظت اللقطة: $out ($(human_size "$out"))"
  else
    fail "تعذّر التقاط لقطة الشاشة."
    return 1
  fi
  return 0
}

# ============================================================
# devices / connect
# ============================================================
cmd_devices() {
  resolve_adb || exit 1
  echo "الأجهزة المتصلة عبر adb:"
  echo "-------------------------"
  "$ADB_BIN" devices -l
  echo
  local real=""
  real="$("$ADB_BIN" devices 2>/dev/null | tail -n +2 | awk '$2=="device"{c++} END{print c+0}')"
  if [[ "$real" == "0" ]]; then
    log_info "لا جهاز متجهز. أنشئ محاكياً: ./scripts/apk-test.sh emulator --create"
    log_info "أو افحص بدون جهاز:      ./scripts/apk-test.sh validate"
  else
    log_ok "$real جهاز جاهز للاختبار."
  fi
  return 0
}

cmd_connect() {
  resolve_adb || exit 1
  local target="$CONNECT_TARGET"
  if [[ -z "$target" ]]; then
    cat >&2 <<'CONN'
الاستخدام: ./scripts/apk-test.sh connect <ip:port>

الطريقة (USB أولاً ثم تحويل إلى الشبكة):
  adb tcpip 5555
  adb connect 192.168.1.20:5555
أو من الهاتف (Android 11+): خيارات المطوّر → Wireless debugging
  adb pair 192.168.1.20:37xxx  <code>
  adb connect 192.168.1.20:4xxxx
CONN
    exit 1
  fi
  run "${ADB_ARR[@]:-$ADB_BIN}" connect "$target"
  SERIAL="$target"
  log_ok "تم ضبط الجهاز على: $target"
}

# ============================================================
# emulator
# ============================================================
cmd_emulator() {
  log_step "المحاكي المحلي"
  local sdk=""
  sdk="$(first_sdk_dir || true)"

  if [[ "$OPT_CREATE_AVD" == "1" ]]; then
    [[ -n "$sdk" ]] || die "أحتاج مسار Android SDK (صدّر ANDROID_HOME أو استخدم --sdk)."
    local mgr=""
    mgr="$(tool_path sdkmanager || true)"
    [[ -n "$mgr" ]] || die "sdkmanager غير موجود — ثبّت Command-line Tools (scripts/android-sdk-setup.sh)."
    log_info "تثبيت حزم المحاكي (~1.5GB — قد يستغرق دقائق)…"
    run "$mgr" --sdk_root="$sdk" "emulator" "platform-tools" "system-images;android-35;google_apis;x86_64"
    log_info "قبول التراخيص…"
    if [[ "$OPT_DRY_RUN" != "1" ]]; then
      yes | "$mgr" --sdk_root="$sdk" --licenses >/dev/null 2>&1 || true
    fi
    local avdmgr=""
    avdmgr="$(tool_path avdmanager || true)"
    [[ -n "$avdmgr" ]] || die "avdmanager غير موجود في $sdk/cmdline-tools/latest/bin"
    log_info "إنشاء AVD باسم: $AVD_NAME"
    printf 'echo "no" | %s create avd -n %s -k "system-images;android-35;google_apis;x86_64" -d pixel_6 --force\n' "$avdmgr" "$AVD_NAME"
    if [[ "$OPT_DRY_RUN" != "1" ]]; then
      printf 'no\n' | "$avdmgr" create avd -n "$AVD_NAME" -k "system-images;android-35;google_apis;x86_64" -d "pixel_6" --force ||
        die "تعذّر إنشاء AVD — تحقق من المساحة و KVM (sudo apt-get install qemu-kvm)."
    fi
    echo
    log_ok "أُنشئ المحاكي '$AVD_NAME'. لتشغيله:"
    printf '  %s/emulator/emulator -avd %s -no-snapshot -no-audio -no-window &\n' "$sdk" "$AVD_NAME"
    printf '  ./scripts/apk-test.sh devices\n'
    printf '  ./scripts/apk-test.sh test --app marketer\n'
    return 0
  fi

  echo "الأجهزة المتجهزة:"
  if resolve_adb 2>/dev/null; then
    adb_devices_list | sed 's/^/  /' | grep . || printf '  (لا شيء)\n'
  else
    printf '  (adb غير مثبت)\n'
  fi
  echo
  echo "أجهزة AVD المتاحة:"
  local emu=""
  emu="$(tool_path emulator || true)"
  if [[ -n "$emu" ]]; then
    "$emu" -list-avds 2>/dev/null | sed 's/^/  /' | grep . || printf '  (لا شيء)\n'
  else
    printf '  (أداة emulator غير مثبتة في SDK)\n'
  fi
  echo
  cat <<'EMU'
لتجهيز محاكي على جهاز عادي (بدون Android Studio):
  sudo apt-get install -y qemu-kvm                 # تسريع على Linux (موصى به)
  ./scripts/apk-test.sh emulator --create          # يثبّت الحزم وينشئ AVD
  ~/android-sdk/emulator/emulator -avd tamm_avd -no-window -no-audio &
  adb wait-for-device && ./scripts/apk-test.sh devices
  ./scripts/apk-test.sh test --app marketer
الحد الأدنى العملي: ~10GB مساحة حرة و 6GB ذاكرة، ومعالج يدعم VT-x/AMD-V.
EMU
}

# ============================================================
# doctor
# ============================================================
cmd_doctor() {
  echo "============================================="
  printf '  TAMMTOOL — تشخيص بيئة الاختبار\n'
  echo "============================================="
  local t
  for t in adb aapt aapt2 apksigner apkanalyzer emulator sdkmanager avdmanager java python3 unzip; do
    local p=""
    p="$(tool_path "$t" 2>/dev/null || true)"
    if [[ -n "$p" ]]; then
      printf '  %s %-14s %s\n' "$C_GREEN✓$C_NC" "$t" "$p"
    else
      printf '  %s %-14s %s\n' "$C_YELLOW•$C_NC" "$t" "غير موجود"
    fi
  done
  echo
  printf '  ANDROID_HOME  : %s\n' "${ANDROID_HOME:-غير مضبوط}"
  printf '  dist/*.apk    : %s\n' "$(ls -1 "$PROJECT_ROOT"/dist/*.apk 2>/dev/null | wc -l | tr -d ' ') ملف جاهز"
  printf '  ملاحظات git   : %s\n' "$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'غير متاح')"
  echo
  if resolve_adb 2>/dev/null; then
    printf '  أجهزة adb:\n'
    "$ADB_BIN" devices | tail -n +2 | sed 's/^/    /' | grep . || printf '    (لا جهاز — validate يعمل بدون جهاز)\n'
  else
    printf '  %s adb غير متاح: أوامر install/launch/logcat لن تعمل، و info/validate ستعمل.\n' "$C_YELLOW!$C_NC"
  fi
  echo
  log_info "فحص سريع بدون جهاز: ./scripts/apk-test.sh validate"
  log_info "اختبار السكربتات:    ./scripts/apk-test.sh selftest"
}

# ============================================================
# test — اختبار حيّ كامل + تقرير
# ============================================================
write_report() {
  local start_ts="${1:-$(date +%s)}"
  [[ "$OPT_DRY_RUN" == "1" ]] && return 0
  mkdir -p "$OUT_DIR" 2>/dev/null || return 0
  local end_ts now base ext
  end_ts="$(date +%s)"
  now="$(date '+%Y-%m-%d %H:%M:%S')"
  base="$(basename "${APK_FILE:-apk}")"
  base="${base%.apk}"
  ext="md"
  [[ "$OPT_JSON" == "1" ]] && ext="json"
  REPORT_FILE="$OUT_DIR/$(date +%Y%m%d-%H%M%S)-$(printf '%s' "${PKG:-$base}")-test.$ext"

  if [[ "$OPT_JSON" == "1" ]]; then
    {
      printf '{\n'
      printf '  "timestamp": "%s",\n' "$now"
      printf '  "duration_seconds": %s,\n' "$((end_ts - start_ts))"
      printf '  "apk": "%s",\n' "${APK_FILE:-}"
      printf '  "package": "%s",\n' "${PKG:-}"
      printf '  "device": "%s",\n' "${SERIAL:-}"
      printf '  "passed": %s,\n' "$CHECKS_PASSED"
      printf '  "failed": %s,\n' "$CHECKS_FAILED"
      printf '  "warnings": %s,\n' "$CHECKS_WARNED"
      printf '  "result": "%s"\n' "$(if [[ $CHECKS_FAILED -gt 0 ]]; then printf 'FAIL'; else printf 'PASS'; fi)"
      printf '}\n'
    } >"$REPORT_FILE"
  else
    {
      printf '# تقرير اختبار APK — TAMMTOOL\n\n'
      printf -- '- التاريخ: %s\n' "$now"
      printf -- '- المدة: %s ثانية\n' "$((end_ts - start_ts))"
      printf -- '- النتيجة: %s\n' "$(if [[ $CHECKS_FAILED -gt 0 ]]; then printf '❌ فشل'; else printf '✅ ناجح'; fi)"
      printf -- '- الملف: `%s`\n' "${APK_FILE:-—}"
      printf -- '- الحجم: %s\n' "$(human_size "${APK_FILE:-}")"
      printf -- '- SHA-256: %s\n' "$(sha256_of "${APK_FILE:-}")"
      printf -- '- الحزمة: %s\n' "${PKG:-—}"
      printf -- '- الجهاز: %s\n' "${SERIAL:-—}"
      printf -- '- الفحوص الناجحة: %s\n' "$CHECKS_PASSED"
      printf -- '- المشاكل: %s\n' "$CHECKS_FAILED"
      printf -- '- التحذيرات: %s\n' "$CHECKS_WARNED"
      if [[ -n "$FAILURES_TEXT" ]]; then
        printf '\n## المشاكل\n\n'
        printf '%s' "$FAILURES_TEXT" | sed '/^$/d; s/^/- /'
      fi
    } >"$REPORT_FILE"
  fi
  printf '  التقرير: %s\n' "$REPORT_FILE"
  return 0
}

cmd_test() {
  apk_required
  detect_badge_tool
  require_device
  resolve_package || exit 1

  local start_ts
  start_ts="$(date +%s)"
  echo "============================================="
  printf '  TAMMTOOL — اختبار حيّ للتطبيق\n'
  echo "============================================="
  printf '  APK     : %s (%s)\n' "$APK_FILE" "$(human_size "$APK_FILE")"
  printf '  الحزمة  : %s\n' "$PKG"
  printf '  الجهاز  : %s\n' "$SERIAL"
  printf '  المهلة  : %s ثانية\n' "$TIMEOUT"
  echo

  log_info "الخطوة 1/5: فحص ثابت"
  if [[ "$OPT_DRY_RUN" == "1" ]]; then
    log_info "[dry-run] تخطي الفحص الثابت."
  else
    local vstatus=0
    cmd_validate >/dev/null 2>&1 || vstatus=$?
    if [[ $vstatus -ne 0 ]]; then
      fail "الفحص الثابت للـ APK فشل — أصلحه أولاً (./scripts/apk-test.sh validate)."
      write_report "$start_ts"
      exit 4
    fi
    CHECKS_PASSED=0
    CHECKS_FAILED=0
    CHECKS_WARNED=0
    FAILURES_TEXT=""
    pass "الفحص الثابت للـ APK"
  fi

  log_info "الخطوة 2/5: التثبيت"
  local -a install_flags=(-r)
  [[ "$OPT_GRANT" == "1" ]] && install_flags+=(-g)
  [[ "$OPT_DOWNGRADE" == "1" ]] && install_flags+=(-d)
  if [[ "$OPT_REINSTALL" == "1" ]]; then
    "${ADB_ARR[@]:-$ADB_BIN}" uninstall "$PKG" >/dev/null 2>&1 || true
  fi
  local out="" status=0
  if [[ "$OPT_DRY_RUN" == "1" ]]; then
    printf '%s\n' "${C_BLUE}\$${C_NC} adb install ${install_flags[*]} $APK_FILE"
  else
    out="$("${ADB_ARR[@]}" install "${install_flags[@]}" "$APK_FILE" 2>&1)" || status=$?
    if [[ $status -ne 0 || "$out" == *Failure* ]]; then
      printf '%s\n' "$out" | sed 's/^/    /' >&2
      [[ "$out" == *INSTALL_FAILED_UPDATE_INCOMPATIBLE* && "$OPT_REINSTALL" != "1" ]] &&
        log_warn "تعارض توقيع مع النسخة المثبتة — أعد المحاولة بـ --reinstall."
      fail "فشل التثبيت."
      write_report "$start_ts"
      exit 2
    fi
    pass "التثبيت على $SERIAL"
  fi

  if [[ "$OPT_NO_LAUNCH" == "1" ]]; then
    log_info "تخطي التشغيل (--no-launch)."
    write_report "$start_ts"
    log_ok "نتيجة الاختبار: ناجح (تثبيت فقط)."
    return 0
  fi

  log_info "الخطوة 3/5: التشغيل"
  local activity=""
  if [[ "$OPT_DRY_RUN" != "1" ]]; then
    activity="$("${ADB_ARR[@]}" logcat -c 2>/dev/null; "${ADB_ARR[@]}" shell cmd package resolve-activity --brief "$PKG" 2>/dev/null | tail -n 1 | tr -d '\r')" || true
    case "$activity" in
      *"$PKG"*) run "${ADB_ARR[@]}" shell am start -W -n "$activity" >/dev/null || true ;;
      *)
        log_warn "تعذّر حلّ النشاط — استخدام monkey."
        run "${ADB_ARR[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
        ;;
    esac

    local pid="" waited=0
    while [[ $waited -lt "$TIMEOUT" ]]; do
      pid="$("${ADB_ARR[@]}" shell pidof "$PKG" 2>/dev/null | tr -d '\r\n' | awk '{print $1}')" || true
      [[ -n "$pid" ]] && break
      sleep 1
      waited=$((waited + 1))
    done
    if [[ -n "$pid" ]]; then
      pass "التطبيق أقلع وبقى عملاً (pid=$pid بعد ${waited}s)"
    else
      fail "التطبيق لم يعمل خلال $TIMEOUT ثانية."
    fi

    log_info "الخطوة 4/5: فحص الانهيارات"
    if [[ "$OPT_NO_LOGCAT" != "1" ]]; then
      local crashes=""
      crashes="$("${ADB_ARR[@]}" logcat -d -v brief 2>/dev/null | grep -E "FATAL EXCEPTION|E AndroidRuntime|ANR in $PKG" | head -n 12)" || true
      if [[ -n "$crashes" ]]; then
        fail "انهار التطبيق أو سجّل ANR:"
        printf '%s\n' "$crashes" | sed 's/^/    /' >&2
        printf '\n  للسجلات الكاملة: ./scripts/apk-test.sh logcat %s\n' "$PKG" >&2
        write_report "$start_ts"
        exit 4
      else
        pass "لا FATAL EXCEPTION ولا ANR."
      fi
      if [[ "$OPT_VERBOSE" == "1" ]]; then
        printf '  %s آخر 40 سطر من سجل الجهاز:%s\n' "$C_BOLD" "$C_NC"
        "${ADB_ARR[@]}" logcat -d -v time 2>/dev/null | tail -n 40 | sed 's/^/    /' || true
      fi
    fi

    if [[ "$OPT_NO_SCREENSHOT" != "1" ]]; then
      log_info "الخطوة 5/5: لقطة الشاشة"
      mkdir -p "$SCREENSHOT_DIR" 2>/dev/null || true
      local shot
      shot="$SCREENSHOT_DIR/$(date +%Y%m%d-%H%M%S)-test.png"
      if "${ADB_ARR[@]}" exec-out screencap -p >"$shot" 2>/dev/null && [[ -s "$shot" ]]; then
        pass "لقطة الشاشة: $shot"
      else
        warn "تعذّر التقاط لقطة الشاشة."
      fi
    fi
  else
    printf '%s\n' "${C_BLUE}\$${C_NC} adb shell am start -W -n <launcher-activity>"
    printf '%s\n' "${C_BLUE}[dry-run]${C_NC} تخطي فحص الانهيارات ولقطة الشاشة."
  fi

  write_report "$start_ts"
  echo
  if [[ "$CHECKS_FAILED" -gt 0 ]]; then
    log_err "نتيجة الاختبار: فشل ($CHECKS_FAILED مشكلة، $CHECKS_PASSED ناجح)."
    printf '%s' "$FAILURES_TEXT" | sed '/^$/d; s/^/  ✗ /' >&2
    exit 4
  fi
  log_ok "نتيجة الاختبار: ناجح ($CHECKS_PASSED فحوص، $CHECKS_WARNED تحذير)."
  return 0
}

# ============================================================
# selftest — اختبار السكربتات نفسها
# ============================================================
cmd_selftest() {
  log_step "اختبار ذاتي لسكربتات TAMMTOOL"
  local f
  for f in "$PROJECT_ROOT/scripts/build-apk.sh" "$SCRIPT_PATH"; do
    if [[ -f "$f" ]]; then
      if bash -n "$f" 2>/dev/null; then
        pass "صيغة bash سليمة: $(basename "$f")"
      else
        fail "خطأ صيغة في: $(basename "$f")"
      fi
    else
      warn "ملف غير موجود للاختبار: $(basename "$f")"
    fi
  done

  if bash "$PROJECT_ROOT/scripts/build-apk.sh" --print-env >/dev/null 2>&1; then
    pass "build-apk.sh --print-env يعمل"
  else
    fail "build-apk.sh --print-env فشل"
  fi

  if bash "$SCRIPT_PATH" --help >/dev/null 2>&1; then
    pass "apk-test.sh --help يعمل"
  else
    fail "apk-test.sh --help فشل"
  fi

  if bash "$SCRIPT_PATH" devices >/dev/null 2>&1; then
    pass "apk-test.sh devices يعمل (أو لا يوجد adb — لا بأس)"
  else
    warn "apk-test.sh devices فشل — adb غير مثبت غالباً."
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck -S warning "$PROJECT_ROOT/scripts/build-apk.sh" "$SCRIPT_PATH" >/dev/null 2>&1; then
      pass "shellcheck: لا تحذيرات"
    else
      warn "shellcheck: توجد ملاحظات — شغّله يدوياً: shellcheck -S warning scripts/*.sh"
    fi
  else
    warn "shellcheck غير مثبت (sudo apt-get install shellcheck)."
  fi

  echo
  if [[ "$CHECKS_FAILED" -gt 0 ]]; then
    log_err "selftest: $CHECKS_FAILED فشل."
    exit 1
  fi
  log_ok "selftest: $CHECKS_PASSED ناجح، $CHECKS_WARNED تحذير."
  return 0
}

# ============================================================
# التوزيع
# ============================================================
main() {
  parse_args "$@"
  case "$COMMAND" in
    info) cmd_info ;;
    validate | check | static-test) cmd_validate ;;
    install) cmd_install ;;
    launch | start) cmd_launch ;;
    uninstall) cmd_uninstall ;;
    logcat) cmd_logcat ;;
    screenshot | shot) cmd_screenshot ;;
    devices | device) cmd_devices ;;
    connect) cmd_connect ;;
    emulator | avd) cmd_emulator ;;
    test | smoke) cmd_test ;;
    doctor) cmd_doctor ;;
    selftest) cmd_selftest ;;
    help | "") usage ;;
    *) die_usage "أمر غير معروف: $COMMAND" ;;
  esac
}

main "$@"
