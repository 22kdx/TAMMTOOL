#!/usr/bin/env bash
#
# build-apk.sh — بناء تطبيقات Android في مستودع TAMMTOOL (APK / AAB)
#
# الإصدار: 2.0 — "اعمل على جهازك العادي"
#
# الهدف من هذا السكريبت: أن يقدر أي شخص، على لابتوب عادي (Linux / macOS /
# WSL / Git Bash على Windows) بدون Android Studio وبدون صلاحيات مدير، أن:
#   1. يكتشف JDK و Android SDK و Gradle تلقائياً (أو يثبّتها محلياً في المشروع).
#   2. يبني نسخة Debug أو Release أو AAB لأي تطبيق في apps/ أو examples/.
#   3. يحصل على ملف APK منسوخ إلى مجلد dist/ مع نسخة، بصمة SHA-256، وسجل بناء.
#   4. يفهم سبب الفشل: السكريبت يستخرج الأخطاء من سجل Gradle ويقترح الحل.
#
# الاستخدام:
#   ./scripts/build-apk.sh [debug|release|bundle|unit-test] [app-name] [خيارات]
#
# أمثلة:
#   ./scripts/build-apk.sh                        # debug لتطبيق marketer
#   ./scripts/build-apk.sh debug marketer
#   ./scripts/build-apk.sh release orders-delivery
#   ./scripts/build-apk.sh bundle all --clean
#   ./scripts/build-apk.sh --app marketer --dry-run
#   ./scripts/build-apk.sh --offline --no-daemon --low-memory debug
#   JAVA_HOME=/usr/lib/jvm/temurin-17 ./scripts/build-apk.sh debug
#
# خيارات مهمة:
#   --app NAME        اختيار التطبيق (اسم المجلد داخل apps/ أو examples/)
#   --all             بناء كل التطبيقات المكتشفة
#   --sdk DIR         مسار Android SDK
#   --jdk DIR         مسار JDK (يُصدَّر إلى JAVA_HOME)
#   --gradle-version V| تحميل/استخدام Gradle بهذه النسخة
#   --setup-sdk       تشغيل scripts/android-sdk-setup.sh عند غياب SDK
#   --offline         بدون إنترنت (استخدم الكاش فقط)
#   --no-daemon       لا تشغّل Gradle daemon (مناسب للأجهزة الضعيفة و CI)
#   --low-memory      إعدادات مخصصة للذاكرة القليلة (< 8GB RAM)
#   --dry-run         اطبع ما سيحدث دون تنفيذ
#   --install         بعد البناء ثبّت على الجهاز عبر apk-test.sh
#   --yes             الرد بـ نعم على كل الأسئلة (للسكربتات و CI)
#
# متغيرات بيئة مدعومة:
#   ANDROID_HOME / ANDROID_SDK_ROOT   مسار SDK
#   JAVA_HOME                          مسار JDK
#   TAMM_GRADLE_VERSION               نسخة Gradle الافتراضية (8.7)
#   TAMM_ANDROID_SDK                  مسار SDK (أولوية أعلى من ANDROID_HOME)
#   TAMM_JDK                          مسار JDK
#   TAMM_GRADLE_DIST_DIR              مجلد تخزين توزيع Gradle المحمّل
#   TAMM_EXTRA_GRADLE_ARGS            وسائط إضافية تُمرَّر إلى Gradle
#   NO_COLOR                            تعطيل الألوان
#
set -euo pipefail

VERSION="2.1.0"

# ============================================================
# المسارات
# ============================================================
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================
# الإعدادات الافتراضية
# ============================================================
BUILD_TYPE="debug"
APP_NAME=""
BUILD_TYPE_SET=0
APP_NAME_SET=0
MODULE=""
GRADLE_VERSION="${TAMM_GRADLE_VERSION:-8.7}"
ANDROID_SDK_DIR="${TAMM_ANDROID_SDK:-}"
JDK_DIR="${TAMM_JDK:-}"
GRADLE_BIN="${TAMM_GRADLE_BIN:-}"
GRADLE_USER_HOME_SET="${TAMM_GRADLE_USER_HOME:-}"
GRADLE_TASK=""
OPT_OFFLINE=0
OPT_NO_DAEMON=0
OPT_LOW_MEM=0
OPT_DRY_RUN=0
OPT_CLEAN=0
OPT_SKIP_ENV=0
OPT_INSTALL_PKGS=0
OPT_ASSUME_YES="${TAMM_YES:-0}"
OPT_VERBOSE=0
OPT_SETUP_SDK=0
OPT_INSTALL=0
OPT_REFRESH=0
OPT_PRINT_ENV=0
DIST_DIR="$PROJECT_ROOT/dist"
LOG_DIR="$PROJECT_ROOT/build-logs"
EXTRA_GRADLE_ARGS=()

# التطبيقات المعروفة مسبقاً (اختصارات) — أي مجلد داخل apps/ أو examples/ أو templates/ يعمل أيضاً
alias_app() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    marketer | marketerapp | afghani | afghani-marketer) printf 'marketer' ;;
    orders-delivery | orders | delivery | ordersapp) printf 'orders-delivery' ;;
    *) printf '%s' "$1" ;;
  esac
}

# ============================================================
# الألوان والسجلات
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

# سؤال المستخدم (يتصرف بأدب في وضع عدم التفاعل)
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
    y | yes | نعم | "ن") return 0 ;;
    *) return 1 ;;
  esac
}

# تنفيذ أمر مع طباعة (يحترم --dry-run)
run_cmd() {
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
  TAMMTOOL — بناء تطبيقات Android محلياً
=============================================

الاستخدام:
  ./scripts/build-apk.sh [نوع_البناء] [اسم_التطبيق] [خيارات]
  ./scripts/build-apk.sh [خيارات] [نوع_البناء] [اسم_التطبيق]

نوع البناء:
  debug        نسخة تصحيح (الافتراضي)  → app-debug.apk
  release      نسخة إصدار               → app-release.apk (أو app-release-unsigned.apk)
  bundle|aab   حزمة نشْر Play Store     → app-release.aab
  unit-test    اختبارات الوحدات JVM      → :app:testDebugUnitTest
  lint         فحص Lint                 → :app:lintDebug

اسم التطبيق:
  marketer  |  orders-delivery  |  أي مجلد داخل apps/ أو examples/ أو templates/  |  all

أمثلة:
  ./scripts/build-apk.sh                              # debug / marketer
  ./scripts/build-apk.sh release orders-delivery      # release APK
  ./scripts/build-apk.sh bundle marketer --clean      # AAB بعد تنظيف
  ./scripts/build-apk.sh unit-test all                # اختبارات وحدات لكل التطبيقات
  ./scripts/build-apk.sh --dry-run --print-env        # ماذا سيُنفَّذ؟ (بدون تنفيذ)
  ./scripts/build-apk.sh debug --offline --low-memory  # على لابتوب ضعيف وبدون إنترنت

الخيارات:
  --app NAME          اسم التطبيق
  --type TYPE         نوع البناء (بديل عن الوسيط الأول)
  --module NAME       اسم وحدة Gradle (الافتراضي: :app)
  --task TASK         مهمة Gradle مخصصة (تتجاوز نوع البناء)
  --sdk DIR           مسار Android SDK
  --jdk DIR           مسار JDK (يُضبط JAVA_HOME)
  --gradle-version V  نسخة Gradle عند الحاجة إلى تحميل/توليد Wrapper
  --setup-sdk         تشغيل scripts/android-sdk-setup.sh إذا كان SDK غائباً
  --install-sdk-pkgs  تثبيت الحزم الناقصة عبر sdkmanager عند توفره
  --offline           تشغيل Gradle بوضع offline
  --no-daemon         تعطيل Gradle daemon
  --low-memory        ذاكرة أقل: -Xmx1536m + إيقاف daemon + workers=2
  --clean             تنفيذ clean قبل البناء
  --refresh           --refresh-dependencies
  --skip-env-check    تخطي فحص البيئة (من أنت متأكد من بيئتك)
  --output-dir DIR    مجلد نسخ المخرجات (الافتراضي: ./dist)
  --install           تثبيت APK الناتج على الجهاز المتصل (apk-test.sh)
  --dry-run           طباعة الأوامر دون تنفيذ
  --print-env         طباعة معلومات البيئة ثم الخروج
  --yes, -y           القبول التلقائي لكل الأسئلة
  --verbose, -v       إخراج موسّع (stacktrace + كل أمر)
  --help, -h          هذه الرسالة
  --version           رقم إصدار السكريبت

متغيرات البيئة:
  ANDROID_HOME / ANDROID_SDK_ROOT / TAMM_ANDROID_SDK   مسار SDK
  JAVA_HOME / TAMM_JDK                                  مسار JDK
  TAMM_GRADLE_VERSION                                   نسخة Gradle (افتراضي 8.7)
  TAMM_GRADLE_DIST_DIR                                  مكان تخزين توزيع Gradle
  TAMM_GRADLE_BIN                                       اسم/مسار تنفيذ gradle يدوياً (يتجاوز التوليد)
  TAMM_EXTRA_GRADLE_ARGS                                وسائط إضافية لـ Gradle
  TAMM_YES=1                                            القبول التلقائي
  NO_COLOR                                              بدون ألوان
HELP
}

# ============================================================
# تحليل الوسائط
# ============================================================
parse_args() {
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      --version)
        echo "build-apk.sh v$VERSION"
        exit 0
        ;;
      debug | assembleDebug)
        BUILD_TYPE="debug"
        BUILD_TYPE_SET=1
        ;;
      release | assembleRelease)
        BUILD_TYPE="release"
        BUILD_TYPE_SET=1
        ;;
      bundle | aab | bundleRelease)
        BUILD_TYPE="bundle"
        BUILD_TYPE_SET=1
        ;;
      unit-test | unit | testDebug)
        BUILD_TYPE="unit-test"
        BUILD_TYPE_SET=1
        ;;
      lint)
        BUILD_TYPE="lint"
        BUILD_TYPE_SET=1
        ;;
      clean)
        BUILD_TYPE="clean"
        BUILD_TYPE_SET=1
        ;;
      all)
        APP_NAME="all"
        APP_NAME_SET=1
        ;;
      --app)
        [[ $# -ge 2 ]] || die "--app يحتاج إلى قيمة"
        APP_NAME="$2"
        APP_NAME_SET=1
        shift
        ;;
      --app=*) APP_NAME="${1#*=}" && APP_NAME_SET=1 ;;
      --type)
        [[ $# -ge 2 ]] || die "--type يحتاج إلى قيمة"
        BUILD_TYPE="$2"
        BUILD_TYPE_SET=1
        shift
        ;;
      --type=*) BUILD_TYPE="${1#*=}" && BUILD_TYPE_SET=1 ;;
      --module)
        [[ $# -ge 2 ]] || die "--module يحتاج إلى قيمة"
        MODULE="$2"
        shift
        ;;
      --module=*) MODULE="${1#*=}" ;;
      --task)
        [[ $# -ge 2 ]] || die "--task يحتاج إلى قيمة"
        BUILD_TYPE="custom"
        GRADLE_TASK="$2"
        shift
        ;;
      --task=*)
        BUILD_TYPE="custom"
        GRADLE_TASK="${1#*=}"
        ;;
      --sdk)
        [[ $# -ge 2 ]] || die "--sdk يحتاج إلى مسار"
        ANDROID_SDK_DIR="$2"
        shift
        ;;
      --sdk=*) ANDROID_SDK_DIR="${1#*=}" ;;
      --jdk)
        [[ $# -ge 2 ]] || die "--jdk يحتاج إلى مسار"
        JDK_DIR="$2"
        shift
        ;;
      --jdk=*) JDK_DIR="${1#*=}" ;;
      --gradle-version)
        [[ $# -ge 2 ]] || die "--gradle-version يحتاج إلى قيمة"
        GRADLE_VERSION="$2"
        shift
        ;;
      --gradle-version=*) GRADLE_VERSION="${1#*=}" ;;
      --output-dir)
        [[ $# -ge 2 ]] || die "--output-dir يحتاج إلى مسار"
        DIST_DIR="$2"
        shift
        ;;
      --output-dir=*) DIST_DIR="${1#*=}" ;;
      --setup-sdk) OPT_SETUP_SDK=1 ;;
      --install-sdk-pkgs) OPT_INSTALL_PKGS=1 ;;
      --offline) OPT_OFFLINE=1 ;;
      --no-daemon) OPT_NO_DAEMON=1 ;;
      --low-memory) OPT_LOW_MEM=1 ;;
      --clean) OPT_CLEAN=1 ;;
      --refresh) OPT_REFRESH=1 ;;
      --skip-env-check) OPT_SKIP_ENV=1 ;;
      --dry-run) OPT_DRY_RUN=1 ;;
      --print-env) OPT_PRINT_ENV=1 ;;
      --install) OPT_INSTALL=1 ;;
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
      -*)
        die "خيار غير معروف: $1  (استخدم --help لعرض المساعدة)"
        ;;
      *)
        positional+=("$1")
        ;;
    esac
    shift
  done

  # الوسائط الموقوفة (توافق مع الاستخدام القديم: build-apk.sh debug marketer)
  local n=${#positional[@]} i=0
  while [[ $i -lt $n ]]; do
    local item="${positional[$i]}"
    if [[ $i -eq 0 && $APP_NAME_SET -eq 0 && $BUILD_TYPE_SET -eq 0 ]] && is_known_app "$item"; then
      APP_NAME="$item"
      APP_NAME_SET=1
    elif [[ $i -eq 0 && $BUILD_TYPE_SET -eq 0 ]]; then
      BUILD_TYPE="$item"
      BUILD_TYPE_SET=1
    elif [[ $APP_NAME_SET -eq 0 ]]; then
      APP_NAME="$item"
      APP_NAME_SET=1
    else
      EXTRA_GRADLE_ARGS+=("$item")
    fi
    i=$((i + 1))
  done

  if [[ -n "${TAMM_EXTRA_GRADLE_ARGS:-}" ]]; then
    # shellcheck disable=SC2206 # قصدنا تقسيم المسافات هنا
    EXTRA_GRADLE_ARGS+=(${TAMM_EXTRA_GRADLE_ARGS})
  fi
}

# ============================================================
# اكتشاف التطبيقات
# ============================================================
is_gradle_project_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 1
  if compgen -G "$dir/settings.gradle*" >/dev/null; then
    return 0
  fi
  compgen -G "$dir/app/build.gradle*" >/dev/null
}

# يطبع أسماء التطبيقات المتاحة (أسماء المجلدات داخل apps/ و examples/)
discover_apps() {
  local base name found=" "
  for base in "$PROJECT_ROOT/apps" "$PROJECT_ROOT/examples" "$PROJECT_ROOT/projects" "$PROJECT_ROOT/templates"; do
    [[ -d "$base" ]] || continue
    for dir in "$base"/*/; do
      [[ -d "$dir" ]] || continue
      is_gradle_project_dir "$dir" || continue
      name="$(basename "$dir")"
      case "$name" in
        build | .*) continue ;;
      esac
      case "$found" in
        *" $name "*) ;;
        *)
          printf '%s\n' "$name"
          found="$found$name "
          ;;
      esac
    done
  done
  return 0
}

app_root_dir() { # المسار الكامل لمجلد التطبيق
  local name="$1"
  local base
  for base in "$PROJECT_ROOT/apps" "$PROJECT_ROOT/examples" "$PROJECT_ROOT/projects" "$PROJECT_ROOT/templates"; do
    if [[ -f "$base/$name/settings.gradle" || -f "$base/$name/settings.gradle.kts" || -d "$base/$name/app" ]]; then
      printf '%s\n' "$base/$name"
      return 0
    fi
  done
  return 1
}

is_known_app() {
  local name
  name="$(alias_app "$1")"
  [[ -n "$name" ]] || return 1
  app_root_dir "$name" >/dev/null 2>&1
}

list_apps() {
  discover_apps | tr '\n' ' ' | sed 's/ $//'
}

# ============================================================
# فحص البيئة: JDK
# ============================================================
java_major_version() {
  local raw first
  raw="$("$1" -version 2>&1 | head -n 1)" || return 1
  first="$(printf '%s' "$raw" | sed -n 's/.*version "\([0-9._]*\)".*/\1/p')"
  [[ -n "$first" ]] || return 1
  local major="${first%%.*}"
  if [[ "$major" == "1" ]]; then
    # صيغة Java 8 وما قبلها: 1.8.0_392
    local rest="${first#1.}"
    major="${rest%%.*}"
  fi
  printf '%s\n' "$major"
}

java_version_string() {
  local raw
  raw="$("$1" -version 2>&1 | head -n 1)" || return 1
  printf '%s\n' "$raw" | sed -n 's/.*version "\([^"]*\)".*/\1/p'
}

valid_jdk_dir() {
  [[ -n "$1" && -x "$1/bin/java" ]]
}

jdk_search_dirs() {
  printf '%s\n' \
    "$JDK_DIR" \
    "${JAVA_HOME:-}" \
    "$HOME/.sdkman/candidates/java/current" \
    "/usr/lib/jvm/java-17-openjdk" \
    "/usr/lib/jvm/java-17-openjdk-amd64" \
    "/usr/lib/jvm/temurin-17-jdk" \
    "/usr/lib/jvm/java-17" \
    "/usr/lib/jvm" \
    "/opt/java/openjdk" \
    "/opt/homebrew/opt/openjdk@17" \
    "/usr/local/opt/openjdk@17" \
    "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" \
    "/mnt/c/Program Files/Eclipse Adoptium/jdk-17.0.0.8-hotspot"
}

setup_java() {
  log_step "التحقق من JDK"
  local candidate="" found=""
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    if valid_jdk_dir "$candidate"; then
      found="$candidate"
      break
    fi
    # مجلد يحوي إصداراً فرعياً (مثل /usr/lib/jvm/java-17-openjdk-amd64/jre)
    if [[ -d "$candidate" ]]; then
      local sub
      for sub in "$candidate"/jdk-17* "$candidate"/*17* "$candidate"/latest; do
        if valid_jdk_dir "$sub"; then
          found="$sub"
          break 2
        fi
      done
    fi
  done < <(jdk_search_dirs)

  if [[ -z "$found" ]] && command -v java >/dev/null 2>&1; then
    found="$(cd "$(dirname "$(command -v java)")/.." && pwd)"
    valid_jdk_dir "$found" || found=""
  fi

  [[ -n "$found" ]] || {
    log_err "لم يتم العثور على JDK 17 أو أحدث."
    cat >&2 <<'JDKHELP'
  ثبّت JDK بأحد هذه الطرق (لا تحتاج صلاحيات مدير في الخيارات الأخيرة):
    Ubuntu/Debian : sudo apt-get install -y openjdk-17-jdk
    Fedora        : sudo dnf install -y java-17-openjdk-devel
    Arch          : sudo pacman -S --noconfirm jdk17-openjdk
    macOS         : brew install --cask temurin@17
    بدون صلاحيات  : curl -s "https://get.sdkman.io" | bash && sdk install java 17.0.11-tem
    أو مرّر المسار: ./scripts/build-apk.sh --jdk /path/to/jdk
JDKHELP
    return 1
  }

  export JAVA_HOME="$found"
  export PATH="$JAVA_HOME/bin:$PATH"
  local major
  major="$(java_major_version "$JAVA_HOME/bin/java" || echo "")"
  JAVA_INFO="$(java_version_string "$JAVA_HOME/bin/java" || echo 'مجهول')"
  if [[ -z "$major" ]]; then
    log_warn "تعذّر قراءة إصدار Java في: $JAVA_HOME"
  elif [[ "$major" -lt 17 ]]; then
    log_err "إصدار Java قديم: $major (من $JAVA_INFO) — البناء يحتاج 17 أو أحدث."
    log_info "حدّد إصداراً أحدث بـ --jdk /path/to/jdk-17"
    return 1
  else
    log_ok "JDK: $JAVA_INFO"
  fi
  log_info "JAVA_HOME=$JAVA_HOME"
  return 0
}

# ============================================================
# تثبيت Android SDK داخلياً (خطة بديلة عند تعذّر scripts/android-sdk-setup.sh)
# ============================================================
sdk_helper_usable() {
  local helper="$PROJECT_ROOT/scripts/android-sdk-setup.sh"
  [[ -f "$helper" ]] || return 1
  bash -n "$helper" 2>/dev/null
}

# يثبّت Command-line Tools + الحزم الأساسية إلى مسار محلي (لا يحتاج sudo)
install_sdk_inline() {
  local target="${1:-$HOME/android-sdk}"
  [[ "$OPT_DRY_RUN" == "1" ]] && {
    log_info "[dry-run] كان سيُثبَّت Android SDK في: $target (cmdline-tools + platforms;android-35 + build-tools)"
    return 0
  }
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || {
    log_err "تثبيت SDK يحتاج curl أو wget."
    return 1
  }
  command -v unzip >/dev/null 2>&1 || {
    log_err "تثبيت SDK يحتاج unzip."
    return 1
  }

  local os arch zipname
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in
    linux)
      [[ "$arch" == "x86_64" || "$arch" == "aarch64" ]] || {
        log_err "بنية غير مدعومة للتثبيت التلقائي: Linux/$arch"
        return 1
      }
      zipname="commandlinetools-linux-11076708_latest.zip"
      ;;
    darwin)
      zipname="commandlinetools-mac-11076708_latest.zip"
      ;;
    *)
      log_err "نظام غير مدعوم للتثبيت التلقائي: $os — استخدم Android Studio SDK Manager."
      return 1
      ;;
  esac

  log_step "تثبيت Android SDK في $target (بدون Android Studio)"
  mkdir -p "$target/cmdline-tools" || return 1
  local zip_path="$target/$zipname"
  local url="https://dl.google.com/android/repository/$zipname"
  log_info "تحميل Command-line Tools…"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 5 -o "$zip_path" "$url" || {
      log_err "فشل التحميل من $url"
      return 1
    }
  else
    wget -q --tries=3 -O "$zip_path" "$url" || {
      log_err "فشل التحميل من $url"
      return 1
    }
  fi
  [[ -s "$zip_path" ]] || {
    log_err "الملف المحمّل فارغ."
    return 1
  }

  rm -rf "$target/cmdline-tools/latest" "$target/.clt-temp"
  mkdir -p "$target/.clt-temp"
  unzip -q -o "$zip_path" -d "$target/.clt-temp" || return 1
  rm -f "$zip_path"
  if [[ -d "$target/.clt-temp/cmdline-tools" ]]; then
    mv "$target/.clt-temp/cmdline-tools" "$target/cmdline-tools/latest"
  else
    mkdir -p "$target/cmdline-tools/latest"
    mv "$target/.clt-temp"/* "$target/cmdline-tools/latest"/ 2>/dev/null || true
  fi
  rm -rf "$target/.clt-temp"
  [[ -x "$target/cmdline-tools/latest/bin/sdkmanager" ]] || {
    log_err "sdkmanager غير موجود بعد التثبيت — فشل غير متوقع."
    return 1
  }
  log_ok "Command-line Tools جاهزة."

  export PATH="$target/cmdline-tools/latest/bin:$target/platform-tools:$PATH"
  log_info "قبول التراخيص…"
  yes | sdkmanager --sdk_root="$target" --licenses >/dev/null 2>&1 || true
  log_info "تثبيت platform-tools و platforms;android-35 و build-tools…"
  sdkmanager --sdk_root="$target" "platform-tools" "platforms;android-35" "build-tools;35.0.0" || {
    log_warn "بعض الحزم لم تُثبَّت — سنحاول البناء رغم ذلك."
  }
  export ANDROID_HOME="$target"
  export ANDROID_SDK_ROOT="$target"
  log_ok "اكتمل تثبيت Android SDK في: $target"
  return 0
}

# ============================================================
# فحص البيئة: Android SDK
# ============================================================
sdk_from_local_properties() {
  local props="$1"
  [[ -f "$props" ]] || return 1
  local val
  val="$(sed -n 's/^[[:space:]]*sdk\.dir[[:space:]]*=[[:space:]]*\(.*\)$/\1/p' "$props" | tail -n 1)"
  [[ -n "$val" ]] || return 1
  # إزالة هروب المسارات في Windows (C\:\\Android\\Sdk → C:/Android/Sdk)
  val="${val//\\:/ :}"
  val="${val//\\//}"
  printf '%s\n' "$val" | sed 's/[[:space:]]*$//'
}

valid_sdk_dir() {
  [[ -n "$1" && -d "$1" ]] || return 1
  [[ -d "$1/platforms" || -d "$1/build-tools" || -d "$1/cmdline-tools" ]]
}

setup_android_sdk() {
  log_step "التحقق من Android SDK"
  local candidate="" found=""
  local lp_val=""
  lp_val="$(sdk_from_local_properties "$APP_DIR/local.properties" 2>/dev/null || true)"
  local props_val=""
  props_val="$(sdk_from_local_properties "$PROJECT_ROOT/local.properties" 2>/dev/null || true)"

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    candidate="${candidate/#\~/$HOME}"
    if valid_sdk_dir "$candidate"; then
      found="$candidate"
      break
    fi
  done < <(
    printf '%s\n' \
      "$ANDROID_SDK_DIR" \
      "$lp_val" \
      "$props_val" \
      "${ANDROID_HOME:-}" \
      "${ANDROID_SDK_ROOT:-}" \
      "$HOME/android-sdk" \
      "$HOME/.android-sdk" \
      "$HOME/Android/Sdk" \
      "$HOME/Library/Android/sdk" \
      "/opt/android-sdk" \
      "/usr/lib/android-sdk" \
      "/usr/local/share/android-sdk" \
      "/snap/android-sdk/current" \
      "$PROJECT_ROOT/android-sdk"
  )

  if [[ -z "$found" ]] && { [[ "$OPT_SETUP_SDK" == "1" ]] || confirm "لم يُعثر على Android SDK. هل تريد تثبيته الآن محلياً؟"; }; then
    if sdk_helper_usable; then
      log_info "استخدام scripts/android-sdk-setup.sh لتثبيت SDK…"
      bash "$PROJECT_ROOT/scripts/android-sdk-setup.sh" --sdk-dir "${ANDROID_SDK_DIR:-$HOME/android-sdk}" --accept-licenses ||
        log_warn "فشل scripts/android-sdk-setup.sh — سأجرّب التثبيت الداخلي."
    else
      [[ -f "$PROJECT_ROOT/scripts/android-sdk-setup.sh" ]] &&
        log_warn "⚠ scripts/android-sdk-setup.sh يحتوي خطأ صيغة (bash -n يفشل) — سأستخدم التثبيت الداخلي بدلاً منه."
    fi
    found="${ANDROID_HOME:-${ANDROID_SDK_DIR:-$HOME/android-sdk}}"
    if ! valid_sdk_dir "$found"; then
      install_sdk_inline "$found" || die "تعذّر تثبيت Android SDK تلقائياً — ثبّته يدوياً ثم أعد المحاولة."
    fi
    valid_sdk_dir "$found" || found=""
  fi

  [[ -n "$found" ]] || {
    log_err "لم يتم العثور على Android SDK."
    cat >&2 <<'SDKHELP'
  اختر أحد الحلول:
    1) تثبيت تلقائي (يحتاج إنترنت فقط، بدون صلاحيات مدير):
         ./scripts/build-apk.sh --setup-sdk debug marketer
    2) تثبيت يدوي من Android Studio ثم:
         export ANDROID_HOME="$HOME/Android/Sdk"
    3) تحديد المسار مباشرة:
         ./scripts/build-apk.sh --sdk /path/to/android-sdk debug marketer
SDKHELP
    return 1
  }

  export ANDROID_HOME="$found"
  export ANDROID_SDK_ROOT="$found"
  [[ -d "$found/platforms" ]] || log_warn "مجلد platforms غير موجود في SDK — قد يحتاج البناء: sdkmanager 'platforms;android-35'"
  [[ -d "$found/build-tools" ]] || log_warn "مجلد build-tools غير موجود — قد يحتاج البناء: sdkmanager 'build-tools;35.0.0'"
  export PATH="$found/platform-tools:$found/cmdline-tools/latest/bin:$PATH"
  log_ok "Android SDK: $ANDROID_HOME"

  # اكتب local.properties حتى يعرف Gradle مكان SDK (ملف مُستثنى من git)
  if [[ ! -f "$APP_DIR/local.properties" ]]; then
    if [[ "$OPT_DRY_RUN" == "1" ]]; then
      log_info "[dry-run] إنشاء $APP_DIR/local.properties (sdk.dir=$ANDROID_HOME)"
    else
      mkdir -p "$APP_DIR"
      printf 'sdk.dir=%s\n' "$ANDROID_HOME" >"$APP_DIR/local.properties"
      log_info "أُنشئ ملف local.properties (محلي فقط، غير متابع في git)."
    fi
  fi

  # تثبيت الحزم الناقصة إن طُلب
  if [[ "${OPT_INSTALL_PKGS:-0}" == "1" ]] && command -v sdkmanager >/dev/null 2>&1; then
    local missing=0
    [[ -d "$found/platforms/android-35" ]] || missing=1
    [[ -d "$found/build-tools/35.0.0" ]] || missing=1
    if [[ $missing -eq 1 ]]; then
      log_info "تثبيت الحزم المطلوبة عبر sdkmanager..."
      run_cmd sdkmanager --sdk_root="$found" --licenses >/dev/null 2>&1 || true
      run_cmd sdkmanager --sdk_root="$found" "platform-tools" "platforms;android-35" "build-tools;35.0.0" ||
        log_warn "تعذّر تثبيت بعض الحزم — سنحاول البناء رغم ذلك."
    else
      log_ok "الحزم الأساسية مثبتة (platforms;android-35، build-tools;35.0.0)."
    fi
  fi
  return 0
}

# ============================================================
# اختيار وحدة Gradle ومهمة البناء
# ============================================================
resolve_module() {
  if [[ -n "$MODULE" ]]; then
    return 0
  fi
  local settings
  for settings in "$APP_DIR/settings.gradle.kts" "$APP_DIR/settings.gradle"; do
    if [[ -f "$settings" ]] && grep -qE 'include\([":]+app' "$settings"; then
      MODULE="app"
      return 0
    fi
  done
  # مشروع أحادي الوحدة: المهام تُنفَّذ على الجذر
  if [[ -f "$APP_DIR/build.gradle.kts" || -f "$APP_DIR/build.gradle" ]]; then
    MODULE=""
    return 0
  fi
  MODULE="app"
}

gradle_task_for_type() {
  case "$BUILD_TYPE" in
    debug) printf 'assembleDebug\n' ;;
    release) printf 'assembleRelease\n' ;;
    bundle | aab) printf 'bundleRelease\n' ;;
    unit-test) printf 'testDebugUnitTest\n' ;;
    lint) printf 'lintDebug\n' ;;
    clean) printf 'clean\n' ;;
    *)
      log_err "نوع بناء غير مدعوم: '$BUILD_TYPE'"
      printf 'الخيارات: debug, release, bundle, unit-test, lint, clean (أو استخدم --task)\n' >&2
      return 1
      ;;
  esac
}

# ============================================================
# اختيار مشغّل Gradle (wrapper ← نظام ← تحميل تلقائي)
# ============================================================
gradle_wrapper_version() {
  local props="$APP_DIR/gradle/wrapper/gradle-wrapper.properties"
  [[ -f "$props" ]] || return 1
  local url
  url="$(sed -n 's/^[[:space:]]*distributionUrl=//p' "$props" | tail -n 1)"
  [[ -n "$url" ]] || return 1
  printf '%s\n' "$url" | sed -n 's/.*gradle-\([0-9][0-9.]*\)-\(bin\|all\)\.zip.*/\1/p'
}

gradle_version_from_cmd() {
  local out
  out="$("$1" --version 2>/dev/null | sed -n 's/^[[:space:]]*Gradle[[:space:]]*\([0-9][0-9.]*\).*/\1/p' | head -n 1)" || return 1
  [[ -n "$out" ]] || return 1
  printf '%s\n' "$out"
}

# يهيّئ مصفوفة GRADLE_CMD لاستخدامها في run_gradle
GRADLE_CMD=()
GRADLE_LABEL=""
setup_gradle() {
  log_step "التحقق من Gradle"

  if [[ -n "$GRADLE_BIN" ]]; then
    # يُقبل اسم أمر مجرّد (مثل: gradle) أو مسار كامل
    if [[ "$GRADLE_BIN" != */* ]] && command -v "$GRADLE_BIN" >/dev/null 2>&1; then
      GRADLE_BIN="$(command -v "$GRADLE_BIN")"
    fi
    [[ -x "$GRADLE_BIN" ]] || die "TAMM_GRADLE_BIN غير قابل للتنفيذ: $GRADLE_BIN"
    GRADLE_CMD=("$GRADLE_BIN")
    GRADLE_LABEL="gradle (--tamm-gradle-bin)"
    log_ok "استخدام Gradle المحدد يدوياً: $GRADLE_BIN"
    return 0
  fi

  # 1) Gradle Wrapper موجود (الحالة المثالية)
  if [[ -f "$APP_DIR/gradlew" ]]; then
    [[ -x "$APP_DIR/gradlew" ]] && : || chmod +x "$APP_DIR/gradlew" 2>/dev/null || true
    if [[ -f "$APP_DIR/gradle/wrapper/gradle-wrapper.jar" ]]; then
      GRADLE_CMD=("./gradlew")
      GRADLE_LABEL="wrapper"
      local wv
      wv="$(gradle_wrapper_version || true)"
      log_ok "Gradle Wrapper جاهز ${wv:+(الإصدار $wv)}"
      return 0
    fi
    log_warn "يوجد gradlew لكن gradle/wrapper/gradle-wrapper.jar مفقود (شائع عند إضافة Wrapper يدوياً)."
    log_info "سأولّد Wrapper من gradle النظام أو أحمّل توزيع Gradle محلياً."
  fi

  # 2) gradle مثبت على النظام: نولّد Wrapper تلقائياً (الأفضل للمشروع) أو نستخدمه مباشرة
  if command -v gradle >/dev/null 2>&1; then
    local sv
    sv="$(gradle_version_from_cmd gradle || echo 'مجهول')"
    log_ok "Gradle على النظام: الإصدار $sv"
    if confirm "توليد Gradle Wrapper داخل $APP_NAME بالإصدار $GRADLE_VERSION؟ (موصى به: يوحّد النسخة محلياً وفي CI)"; then
      (
        cd "$APP_DIR"
        run_cmd gradle wrapper "--gradle-version=$GRADLE_VERSION" --console=plain
      ) || log_warn "تعذّر توليد الـ Wrapper — سنستخدم gradle مباشرة."
      if [[ -x "$APP_DIR/gradlew" || -f "$APP_DIR/gradlew" ]]; then
        chmod +x "$APP_DIR/gradlew" 2>/dev/null || true
        GRADLE_CMD=("./gradlew")
        GRADLE_LABEL="wrapper (مولّد)"
        return 0
      fi
    fi
    GRADLE_CMD=("gradle")
    GRADLE_LABEL="system gradle"
    return 0
  fi

  # 3) سكريبت المشروع المساعد إن وُجد
  if [[ -f "$PROJECT_ROOT/scripts/download-gradlew.sh" ]]; then
    log_info "لا يوجد Wrapper ولا gradle على النظام — تجربة scripts/download-gradlew.sh"
    bash "$PROJECT_ROOT/scripts/download-gradlew.sh" "$GRADLE_VERSION" || true
    if [[ -f "$APP_DIR/gradlew" ]]; then
      chmod +x "$APP_DIR/gradlew" 2>/dev/null || true
      GRADLE_CMD=("./gradlew")
      GRADLE_LABEL="wrapper"
      return 0
    fi
  fi

  # 4) تحميل توزيع Gradle محلياً داخل كاش المستخدم (لا يحتاج صلاحيات مدير)
  bootstrap_gradle && return 0

  log_err "لا يوجد Gradle ولا Wrapper، وتعذّر تجهيز أحدهما."
  printf '  الحلول:\n' >&2
  printf '    • ثبّت Gradle: sdk install gradle 8.7  (أو من gradle.org)\n' >&2
  printf '    • أو أضف Wrapper إلى المشروع: gradle wrapper --gradle-version %s\n' "$GRADLE_VERSION" >&2
  printf '    • أو حدّد مساراً يدوياً: TAMM_GRADLE_BIN=/path/to/gradle ./scripts/build-apk.sh debug\n' >&2
  return 1
}

# يحمّل توزيع Gradle إلى كاش المستخدم ثم يستخدمه
bootstrap_gradle() {
  local dist_root="${TAMM_GRADLE_DIST_DIR:-$HOME/.cache/tammtool/gradle}"
  local gradle_home="$dist_root/gradle-$GRADLE_VERSION"
  local gradle_exec="$gradle_home/bin/gradle"

  if [[ "$OPT_DRY_RUN" == "1" ]]; then
    log_info "[dry-run] لا يوجد Gradle — كان سيُحمَّل التوزيع $GRADLE_VERSION إلى: $dist_root"
    GRADLE_CMD=("gradle")
    GRADLE_LABEL="dry-run"
    return 0
  fi

  if [[ -x "$gradle_exec" ]]; then
    log_ok "استخدام توزيع Gradle المحفوظ: $gradle_exec"
    GRADLE_CMD=("$gradle_exec")
    GRADLE_LABEL="bootstrap (cached)"
    return 0
  fi

  [[ "$OPT_OFFLINE" == "1" ]] && {
    log_warn "لا يوجد Gradle مثبت ووضع --offline مفعّل — لا يمكن تحميله."
    return 1
  }

  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || {
    log_err "لا يوجد curl ولا wget لتحميل Gradle."
    return 1
  }
  command -v unzip >/dev/null 2>&1 || {
    log_err "لا يوجد unzip لفك ضغط توزيع Gradle."
    return 1
  }

  log_info "لا يوجد Gradle على الجهاز. سيُحمَّل التوزيع الرسمي (~130MB) إلى: $dist_root"
  log_info "هذا يحدث مرة واحدة فقط؛ البناءات التالية ستستخدم النسخة المحفوظة."
  confirm "هل تريد تحميل Gradle $GRADLE_VERSION الآن؟" || return 1

  local tmp_zip="$dist_root/gradle-$GRADLE_VERSION-bin.zip"
  mkdir -p "$dist_root" || return 1
  local url="https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 3 -o "$tmp_zip" "$url" || return 1
  else
    wget -O "$tmp_zip" "$url" || return 1
  fi

  unzip -q -o "$tmp_zip" -d "$dist_root" || return 1
  rm -f "$tmp_zip"
  [[ -f "$gradle_exec" ]] || {
    log_err "اكتمل التحميل لكن $gradle_exec غير موجود."
    return 1
  }
  chmod +x "$gradle_exec" 2>/dev/null || true
  GRADLE_CMD=("$gradle_exec")
  GRADLE_LABEL="bootstrap (downloaded)"
  log_ok "تم تجهيز Gradle: $gradle_exec"
  return 0
}

# ============================================================
# تشغيل Gradle
# ============================================================
build_gradle_args() {
  GRADLE_ARGS=()
  GRADLE_ARGS+=("--console=plain")
  [[ "$OPT_OFFLINE" == "1" ]] && GRADLE_ARGS+=("--offline")
  if [[ "$OPT_NO_DAEMON" == "1" || "$OPT_LOW_MEM" == "1" || -n "${CI:-}" ]]; then
    GRADLE_ARGS+=("--no-daemon")
  fi
  [[ "$OPT_REFRESH" == "1" ]] && GRADLE_ARGS+=("--refresh-dependencies")
  [[ "$OPT_VERBOSE" == "1" ]] && GRADLE_ARGS+=("--stacktrace" "--info")
  if [[ "$OPT_LOW_MEM" == "1" ]]; then
    GRADLE_ARGS+=("--max-workers=2")
    export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.jvmargs=-Xmx1536m -Dkotlin.daemon.jvm.options=-Xmx1024m"
  fi
  # تنبيه مفيد لأصحاب الأجهزة الضعيفة
  if [[ "$OPT_LOW_MEM" != "1" && -r /proc/meminfo ]]; then
    local mem_kb
    mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
    if [[ "$mem_kb" -gt 0 && "$mem_kb" -lt 6000000 ]]; then
      log_warn "الذاكرة الإجمالية أقل من ~6GB — أضف --low-memory لتقليل استهلاك Gradle."
    fi
  fi
  if [[ -n "$GRADLE_USER_HOME_SET" ]]; then
    GRADLE_ARGS+=("--gradle-user-home" "$GRADLE_USER_HOME_SET")
  fi
  if [[ ${#EXTRA_GRADLE_ARGS[@]} -gt 0 ]]; then
    GRADLE_ARGS+=("${EXTRA_GRADLE_ARGS[@]}")
  fi
}

LOG_FILE=""

run_gradle() {
  local task="$1"
  local full_task="$task"
  [[ -n "$MODULE" ]] && full_task=":$MODULE:$task"

  local cmd=("${GRADLE_CMD[@]}" "$full_task" "${GRADLE_ARGS[@]+"${GRADLE_ARGS[@]}"}")
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  LOG_FILE="$LOG_DIR/$(basename "$APP_DIR")-$BUILD_TYPE-$(date +%Y%m%d-%H%M%S).log"

  log_step "التنفيذ في $APP_DIR"
  printf '%s\n' "  التطبيق: $APP_DISPLAY"
  printf '%s\n' "  المشغّل: Gradle ($GRADLE_LABEL) — المهمة: $full_task"
  [[ "$OPT_CLEAN" == "1" ]] && printf '%s\n' "  التنظيف: نعم (clean قبل البناء)"
  printf '%s\n' "  السجل: $LOG_FILE"
  echo

  if [[ "$OPT_DRY_RUN" == "1" ]]; then
    printf '%s\n' "${C_BLUE}[dry-run]${C_NC} (cd $APP_DIR && ${cmd[*]})"
    return 0
  fi

  local status=0
  (
    cd "$APP_DIR"
    if [[ "$OPT_CLEAN" == "1" ]]; then
      "${GRADLE_CMD[@]}" "${MODULE:+:$MODULE}:clean" "${GRADLE_ARGS[@]+"${GRADLE_ARGS[@]}"}" || true
    fi
    set -o pipefail
    "${cmd[@]}" 2>&1 | tee "$LOG_FILE"
  ) && status=0 || status=$?

  if [[ $status -ne 0 ]]; then
    diagnose_failure "$LOG_FILE"
    return "$status"
  fi
  return 0
}

# استخراج سبب الفشل واقتراح الحل
diagnose_failure() {
  local log="$1"
  [[ -f "$log" ]] || return 0
  echo
  log_err "فشل البناء. أهم الأسطر من السجل:"
  grep -nE '^(e:|> Task .* FAILED|FAILURE:|\* What went wrong:|error:|.*error: )' "$log" 2>/dev/null | head -n 15 | sed 's/^/    /' || true
  echo
  log_info "تلميحات حسب الخطأ:"
  grep -qi 'SDK location not found' "$log" &&
    printf '    • Gradle لم يجد Android SDK: استخدم --sdk /path أو صدّر ANDROID_HOME.\n'
  grep -qi 'Failed to find target with hash string\|platforms;android' "$log" &&
    printf '    • منصة Android غير مثبتة: sdkmanager "platforms;android-35".\n'
  grep -qi 'license' "$log" &&
    printf '    • التراخيص غير مقبولة: yes | sdkmanager --licenses\n'
  grep -qi 'Unsupported class file major version\|JvmRuntime\|Java 8\|but was compiled with' "$log" &&
    printf '    • إصدار Java غير متوافق: تحتاج JDK 17 (استخدم --jdk).\n'
  grep -qi 'OutOfMemory\|Java heap space\|GC overhead' "$log" &&
    printf '    • نفاد ذاكرة JVM: أعد المحاولة بـ --low-memory أو زوّد الذاكرة/أغلق التطبيقات.\n'
  grep -qi 'Could not resolve\|Could not find\|No cached version' "$log" &&
    printf '    • تعذّر تنزيل اعتماديات: تأكد من الإنترنت، أو أزل --offline، أو جرّب --refresh.\n'
  grep -qi 'Network is unreachable\|Connection refused\|Could not GET' "$log" &&
    printf '    • لا يوجد اتصال بخدمة Gradle/Maven: جرّب من شبكة أخرى أو فعّل --offline بعد تجهيز الكاش.\n'
  grep -qi 'keystore' "$log" &&
    printf '    • التوقيع يحتاج keystore: راجع scripts/sign-apk.sh أو docs/local-build-and-test.md.\n'
  grep -qi 'Kotlin compilation error\|^e: ' "$log" &&
    printf '    • أخطاء ترجمة Kotlin/Java: افتح الملف في المحرر وصحّح الأسطر المذكورة.\n'
  printf '    • السجل الكامل: %s\n' "$log"
  return 0
}

# ============================================================
# locating & نسخ المخرجات
# ============================================================
find_output_file() {
  local kind="$1" # apk | aab
  local dir="" ext="" newest=""
  case "$kind" in
    apk)
      dir="$OUTPUTS_DIR/apk"
      ext="apk"
      ;;
    aab)
      dir="$OUTPUTS_DIR/bundle"
      ext="aab"
      ;;
  esac
  [[ -d "$dir" ]] || return 1
  newest="$(find "$dir" -type f -name "*.$ext" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2- || true)"
  [[ -z "$newest" ]] && newest="$(find "$dir" -type f -name "*.$ext" 2>/dev/null | head -n 1 || true)"
  [[ -n "$newest" && -f "$newest" ]] || return 1
  printf '%s\n' "$newest"
}

# قراءة الإصدار من build.gradle لتسمية الملف
read_gradle_field() {
  local key="$1" file="$2" val=""
  val="$(sed -n "s/.*${key}[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" 2>/dev/null | head -n 1)"
  [[ -z "$val" ]] && val="$(sed -n "s/.*${key}[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" 2>/dev/null | head -n 1)"
  [[ -n "$val" ]] && printf '%s\n' "$val"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    printf 'غير متاح\n'
  fi
}

human_size() {
  local bytes=""
  if stat -c %s "$1" >/dev/null 2>&1; then
    bytes="$(stat -c %s "$1")"
  else
    bytes="$(stat -f %z "$1" 2>/dev/null || echo 0)"
  fi
  [[ -n "$bytes" && "$bytes" -gt 0 ]] 2>/dev/null || {
    printf '%s\n' 'مجهول'
    return
  }
  awk -v b="$bytes" 'BEGIN { s="B KB MB GB"; split(s,u," "); i=1; while (b>=1024 && i<4) { b/=1024; i++ } printf "%.1f %s", b, u[i] }'
}

copy_to_dist() {
  local src="$1" kind="$2"
  [[ -f "$src" ]] || return 0
  local gradle_file="$APP_DIR/$MODULE_DIR_REL/build.gradle.kts"
  [[ -f "$gradle_file" ]] || gradle_file="$APP_DIR/$MODULE_DIR_REL/build.gradle"
  [[ -f "$gradle_file" ]] || gradle_file="$APP_DIR/app/build.gradle.kts"
  local vname="" gitsha="" name="" dest=""
  vname="$(read_gradle_field versionName "$gradle_file" || true)"
  [[ -n "$vname" ]] || vname="0.0.0"
  gitsha="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'nogit')"
  name="${APP_NAME}-${BUILD_TYPE}-v${vname}-${gitsha}.${kind}"
  dest="$DIST_DIR/$name"

  [[ "$OPT_DRY_RUN" == "1" ]] && {
    log_info "[dry-run] نسخ $src → $dest"
    return 0
  }
  mkdir -p "$DIST_DIR"
  cp -f "$src" "$dest"
  local sum
  sum="$(sha256_of "$dest")"
  printf '%s\n' "$sum" >"$dest.sha256"
  {
    printf 'app=%s\n' "$APP_NAME"
    printf 'build_type=%s\n' "$BUILD_TYPE"
    printf 'artifact=%s\n' "$dest"
    printf 'version_name=%s\n' "$vname"
    printf 'git=%s\n' "$gitsha"
    printf 'built_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'sha256=%s\n' "$sum"
    printf 'size=%s\n' "$(human_size "$dest")"
  } >"$DIST_DIR/latest-${APP_NAME}-${BUILD_TYPE}.env"

  log_ok "نُسخت المخرجات إلى: ${C_BOLD}$dest${C_NC} ($(human_size "$dest"))"
  DIST_ARTIFACT="$dest"
  return 0
}

# ============================================================
# بناء تطبيق واحد
# ============================================================
APP_DISPLAY=""
MODULE_DIR_REL="app"
OUTPUTS_DIR=""
DIST_ARTIFACT=""
GRADLE_ARGS=()

build_app() {
  local name="$1"
  APP_NAME="$name"
  APP_DIR="$(app_root_dir "$name")" || die "تعذّر تحديد مسار التطبيق: $name"
  APP_DISPLAY="$name"

  # اسم الوحدة: إن وُجدت app/ فهي الوحدة المستهدفة
  resolve_module
  if [[ -n "$MODULE" ]]; then
    MODULE_DIR_REL="$MODULE"
  else
    MODULE_DIR_REL="."
  fi
  # مخرجات Gradle تُكتب في <module>/build/outputs
  OUTPUTS_DIR="$APP_DIR/$MODULE_DIR_REL/build/outputs"

  local task
  if [[ "$BUILD_TYPE" == "custom" ]]; then
    task="$GRADLE_TASK"
    [[ -n "$task" ]] || die "--task فارغة"
  else
    task="$(gradle_task_for_type)" || return 1
  fi

  echo "============================================="
  printf '  TAMMTOOL — بناء تطبيق Android (محلي)\n'
  echo "============================================="
  printf '  التطبيق    : %s\n' "$APP_DISPLAY"
  printf '  المجلد     : %s\n' "$APP_DIR"
  printf '  نوع البناء : %s\n' "$BUILD_TYPE"
  printf '  الوحدة     : %s\n' "${MODULE:-<جذر المشروع>}"
  printf '  SDK        : %s\n' "${ANDROID_HOME:-غير مضبوط}"
  printf '  JDK        : %s\n' "${JAVA_HOME:-غير مضبوط}"
  echo

  if [[ "$OPT_SKIP_ENV" != "1" ]]; then
    setup_java || exit 1
    setup_android_sdk || exit 1
    setup_gradle || exit 1
  else
    if [[ ! -x "$APP_DIR/gradlew" ]] && ! command -v gradle >/dev/null 2>&1 && [[ -z "$GRADLE_BIN" ]]; then
      log_warn "--skip-env-check مع عدم وجود gradlew/gradle — سنحاول استخدام ./gradlew على أي حال."
      GRADLE_CMD=("./gradlew")
      GRADLE_LABEL="wrapper (مفترض)"
    elif [[ ! -x "$APP_DIR/gradlew" ]] && command -v gradle >/dev/null 2>&1; then
      GRADLE_CMD=("gradle")
      GRADLE_LABEL="system gradle"
    else
      GRADLE_CMD=("./gradlew")
      GRADLE_LABEL="wrapper"
      chmod +x "$APP_DIR/gradlew" 2>/dev/null || true
    fi
  fi

  build_gradle_args
  run_gradle "$task" || return 1

  case "$BUILD_TYPE" in
    unit-test | lint)
      log_ok "اكتملت: $task"
      [[ -f "$LOG_FILE" ]] && printf '  التقرير: %s\n' "$LOG_FILE"
      return 0
      ;;
  esac

  [[ "$OPT_DRY_RUN" == "1" ]] && {
    log_info "[dry-run] تخطي نسخ المخرجات."
    return 0
  }

  local kind="apk" out=""
  [[ "$BUILD_TYPE" == "bundle" ]] && kind="aab"
  if ! out="$(find_output_file "$kind")"; then
    # مسميات بديلة (مثلاً release غير موقّع)
    local alt=""
    alt="$(find "$OUTPUTS_DIR" -type f -name "*.$kind" 2>/dev/null | sort -t/ -k1 | head -n 1 || true)"
    if [[ -n "$alt" ]]; then
      out="$alt"
      log_warn "استُخدم ملف مخرجات بديل: $out"
    else
      log_err "اكتمل البناء لكن لم أعثر على ملف .$kind المتوقع."
      printf '  توقعت ملفاً داخل: %s\n' "$OUTPUTS_DIR" >&2
      printf '  راجع السجل: %s\n' "${LOG_FILE:-build-logs/}" >&2
      return 1
    fi
  fi

  log_ok "تم البناء بنجاح."
  printf '  الملف    : %s\n' "$out"
  printf '  الحجم    : %s\n' "$(human_size "$out")"
  case "$out" in
    *unsigned*)
      log_warn "هذا الملف غير موقّع (app-release-unsigned.apk) ولن يُثبَّت على جهاز."
      printf '  للتوقيع: ./scripts/sign-apk.sh "%s"  أو راجع docs/local-build-and-test.md\n' "$out"
      ;;
  esac

  copy_to_dist "$out" "$kind" || true

  if [[ "$OPT_INSTALL" == "1" ]]; then
    local target="${DIST_ARTIFACT:-$out}"
    if [[ -x "$SCRIPT_DIR/apk-test.sh" || -f "$SCRIPT_DIR/apk-test.sh" ]]; then
      log_step "تثبيت على الجهاز المتصل"
      bash "$SCRIPT_DIR/apk-test.sh" install "$target" || return 1
    else
      log_warn "لا يوجد scripts/apk-test.sh — تجاهل التثبيت."
    fi
  fi

  echo
  printf 'للاختبار على جهاز متصل:\n'
  printf '  ./scripts/apk-test.sh test %s\n' "${DIST_ARTIFACT:-$out}"
  printf 'وللتحقق بدون جهاز (لا يحتاج هاتف):\n'
  printf '  ./scripts/apk-test.sh validate %s\n' "${DIST_ARTIFACT:-$out}"
  echo
  return 0
}

# ============================================================
# طباعة البيئة
# ============================================================
print_env() {
  echo "TAMMTOOL — بيئة البناء المحلية"
  echo "--------------------------------"
  local _apps=""
  _apps="$(list_apps)"
  printf 'التطبيقات المكتشفة  : %s\n' "${_apps:-لا شيء — توقّع apps/<app>/settings.gradle(.kts)}"
  printf 'PROJECT_ROOT       : %s\n' "$PROJECT_ROOT"
  printf 'ANDROID_HOME       : %s\n' "${ANDROID_HOME:-غير مضبوط}"
  printf 'TAMM_ANDROID_SDK   : %s\n' "${TAMM_ANDROID_SDK:-غير مضبوط}"
  printf 'JAVA_HOME          : %s\n' "${JAVA_HOME:-غير مضبوط}"
  printf 'java (PATH)        : %s\n' "$(command -v java || echo 'غير موجود')"
  printf 'gradle (PATH)      : %s\n' "$(command -v gradle || echo 'غير موجود')"
  printf 'adb (PATH)         : %s\n' "$(command -v adb || echo 'غير موجود')"
  printf 'curl / unzip       : %s / %s\n' "$(command -v curl || echo 'غير موجود')" "$(command -v unzip || echo 'غير موجود')"
  local _w=""
  _w="$(ls -1 "$PROJECT_ROOT"/apps/*/gradlew "$PROJECT_ROOT"/examples/*/gradlew "$PROJECT_ROOT"/templates/*/gradlew 2>/dev/null | head -n 3 | tr '\n' ' ' | sed 's/ $//' || true)"
  printf 'Gradle wrapper     : %s\n' "${_w:-لا يوجد — سيولّده build-apk.sh عند أول بناء}"
  printf 'كاش ~/.gradle      : %s\n' "$(if [[ -d "$HOME/.gradle" ]]; then echo 'موجود (البناء التالي أسرع)'; else echo 'غير موجود — أول بناء سينزّل الاعتماديات (~2-5 GB)'; fi)"
  printf 'الذاكرة الكلية      : %s\n' "$(awk '/MemTotal/ {printf "%.1f GB", $2/1048576}' /proc/meminfo 2>/dev/null || echo 'غير متاح')"
  printf 'إصدار git          : %s\n' "$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'غير متاح')"
  printf 'Gradle مطلوب       : %s (يتوافق مع CI)\n' "$GRADLE_VERSION"
}

# ============================================================
# التنفيذ
# ============================================================
LOCK_DIR=""

cleanup_lock() {
  [[ -n "$LOCK_DIR" && -d "$LOCK_DIR" ]] && rmdir "$LOCK_DIR" 2>/dev/null || true
}

main() {
  parse_args "$@"

  if [[ "$OPT_PRINT_ENV" == "1" ]]; then
    print_env
    exit 0
  fi

  # قائمة التطبيقات المطلوب بناؤها
  local apps=()
  local discovered=""
  discovered="$(discover_apps)"

  if [[ "$APP_NAME" == "all" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && apps+=("$line")
    done <<<"$discovered"
    [[ ${#apps[@]} -gt 0 ]] || die "لم أعثر على أي مشروع Gradle داخل apps/ أو examples/ أو templates/"
  elif [[ -n "$APP_NAME" ]]; then
    local resolved
    resolved="$(alias_app "$APP_NAME")"
    if is_known_app "$resolved"; then
      apps=("$resolved")
    else
      log_err "اسم تطبيق غير معروف: '$APP_NAME'"
      printf '  التطبيقات المتاحة: %s\n' "$(printf '%s' "$discovered" | tr '\n' ' ' | sed 's/ $//')" >&2
      printf '  أو: all لبناء كل التطبيقات (كل مجلد داخل apps/ أو examples/ يعمل تلقائياً).\n' >&2
      exit 1
    fi
  elif is_known_app "marketer"; then
    apps=("marketer")
    log_info "لم يُحدد تطبيق — الافتراضي: marketer"
  else
    local first=""
    first="$(printf '%s\n' "$discovered" | head -n 1)"
    local count=""
    count="$(printf '%s\n' "$discovered" | grep -c . || true)"
    if [[ "$count" == "1" && -n "$first" ]]; then
      apps=("$first")
      log_info "تطبيق واحد مكتشف — سيتم بناؤه: $first"
    elif [[ "$count" -gt 1 ]]; then
      log_err "لم أجد تطبيقاً افتراضياً (لا يوجد apps/marketer)."
      printf '  حدّد واحداً من: %s\n' "$(printf '%s' "$discovered" | tr '\n' ' ' | sed 's/ $//')" >&2
      exit 1
    else
      log_err "لم أعثر على مشاريع Android في هذا المستودع."
      printf '  توقعت وجود <apps|examples|templates>/<اسم>/settings.gradle(.kts) أو …/app/build.gradle(.kts)\n' >&2
      exit 1
    fi
  fi

  APP_NAME="${apps[0]}"

  # قفل بسيط يمنع بناءين متزامنين على نفس المستودع
  LOCK_DIR="${TMPDIR:-/tmp}/.tamm-build-$(printf '%s' "$PROJECT_ROOT" | cksum | tr -cd '0-9').lock"
  if [[ "$OPT_DRY_RUN" != "1" ]]; then
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
      local stale="$LOCK_DIR"
      LOCK_DIR=""
      die "يوجد بناء آخر قيد التشغيل على هذا المستودع. إذا كان هذا خطأً احذف: $stale"
    fi
    trap cleanup_lock EXIT INT TERM
  fi

  local rc=0 built=0 app
  for app in "${apps[@]}"; do
    built=$((built + 1))
    if ! build_app "$app"; then
      rc=1
      [[ ${#apps[@]} -gt 1 ]] && log_err "فشل بناء '$app'."
    fi
  done

  if [[ $rc -eq 0 ]]; then
    log_ok "اكتمل البناء (${built} تطبيق)."
    local newest=""
    newest="$(ls -1t "$DIST_DIR"/*.apk "$DIST_DIR"/*.aab 2>/dev/null | head -n 1 || true)"
    [[ -n "$newest" ]] && printf '  أحدث مخرج: %s\n' "$newest"
  fi
  exit "$rc"
}

main "$@"
