#!/usr/bin/env bash
#
# build-apk.sh - سكريبت مساعدة لبناء تطبيقات Android (APK / AAB)
# جزء من مستودع TAMMTOOL
#
# يدعم بناء التطبيقين:
#   1. orders-delivery (التطبيق الرئيسي - إدارة الطلبات والتوصيل)
#   2. marketer        (تطبيق المسوق - طلبات الأفغاني)
#
# الاستخدام:
#   ./scripts/build-apk.sh [debug|release|bundle] [app-name]
#
# أمثلة:
#   ./scripts/build-apk.sh debug marketer
#   ./scripts/build-apk.sh release orders-delivery
#   ./scripts/build-apk.sh bundle marketer
#
# إذا لم يتم تحديد نوع البناء، الافتراضي هو debug.
# إذا لم يتم تحديد التطبيق، الافتراضي هو marketer.

set -euo pipefail

# ============================================================
# الإعدادات
# ============================================================
BUILD_TYPE="${1:-debug}"
APP_NAME="${2:-marketer}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# دعم أسماء التطبيقات
case "$APP_NAME" in
  marketer|afghani|طلبات-الأفغاني)
    APP_DIR="$PROJECT_ROOT/apps/marketer"
    APP_MODULE="app"
    APK_OUTPUT_DEBUG="app/build/outputs/apk/debug/app-debug.apk"
    APK_OUTPUT_RELEASE="app/build/outputs/apk/release/app-release.apk"
    AAB_OUTPUT="app/build/outputs/bundle/release/app-release.aab"
    APP_DISPLAY_NAME="طلبات الأفغاني (تطبيق المسوق)"
    ;;
  orders-delivery|orders|التوصيل)
    APP_DIR="$PROJECT_ROOT/apps/orders-delivery"
    APP_MODULE="app"
    APK_OUTPUT_DEBUG="app/build/outputs/apk/debug/app-debug.apk"
    APK_OUTPUT_RELEASE="app/build/outputs/apk/release/app-release.apk"
    AAB_OUTPUT="app/build/outputs/bundle/release/app-release.aab"
    APP_DISPLAY_NAME="إدارة الطلبات والتوصيل (التطبيق الرئيسي)"
    ;;
  *)
    echo "خطأ: اسم تطبيق غير معروف '$APP_NAME'."
    echo "التطبيقات المتاحة: marketer, orders-delivery"
    exit 1
    ;;
esac

# ألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[ℹ]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

# ============================================================
# التحقق من وجود Android SDK
# ============================================================
ensure_android_sdk() {
  if [[ -z "${ANDROID_HOME:-}" ]]; then
    if [[ -d "$HOME/android-sdk" ]]; then
      export ANDROID_HOME="$HOME/android-sdk"
    elif [[ -d "$HOME/Android/Sdk" ]]; then
      export ANDROID_HOME="$HOME/Android/Sdk"
    else
      log_warn "متغير ANDROID_HOME غير مضبط ولم يتم العثور على Android SDK."
      log_info "هل تريد تثبيت Android SDK تلقائياً؟ (y/n)"
      read -r response
      if [[ "$response" == "y" || "$response" == "Y" ]]; then
        "$PROJECT_ROOT/scripts/android-sdk-setup.sh" --accept-licenses
        export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
      else
        log_error "لا يمكن الاستمرار بدون Android SDK."
        exit 1
      fi
    fi
  fi

  export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

  if [[ ! -d "$ANDROID_HOME" ]]; then
    log_error "مجلد Android SDK غير موجود: $ANDROID_HOME"
    log_info "شغل الأمر التالي لتثبيته: ./scripts/android-sdk-setup.sh --accept-licenses"
    exit 1
  fi

  log_ok "Android SDK موجود في: $ANDROID_HOME"
}

# ============================================================
# التحقق من وجود Gradle Wrapper
# ============================================================
ensure_gradlew() {
  cd "$APP_DIR"

  if [[ ! -x "./gradlew" ]]; then
    log_info "Gradle Wrapper غير موجود. جاري إنشاؤه..."
    if command -v gradle &> /dev/null; then
      gradle wrapper --gradle-version 8.5
    else
      log_error "Gradle غير مثبت ولا يوجد Gradle Wrapper."
      log_info "يرجى تثبيت Gradle أو تشغيل السكريبت من بيئة تحتوي على Gradle."
      exit 1
    fi
  fi

  chmod +x ./gradlew
  log_ok "Gradle Wrapper جاهز."
}

# ============================================================
# البناء
# ============================================================
do_build() {
  cd "$APP_DIR"

  echo "============================================="
  echo "  TAMMTOOL - بناء تطبيق Android"
  echo "============================================="
  echo "التطبيق: $APP_DISPLAY_NAME"
  echo "المسار: $APP_DIR"
  echo "نوع البناء: $BUILD_TYPE"
  echo "Android SDK: ${ANDROID_HOME:-غير مضبط}"
  echo ""

  ensure_android_sdk
  ensure_gradlew

  case "$BUILD_TYPE" in
    debug)
      log_info "بدء بناء نسخة التصحيح (Debug APK)..."
      ./gradlew ":$APP_MODULE:assembleDebug"
      OUTPUT="$APK_OUTPUT_DEBUG"
      ;;
    release)
      log_info "بدء بناء نسخة الإصدار (Release APK)..."
      ./gradlew ":$APP_MODULE:assembleRelease"
      OUTPUT="$APK_OUTPUT_RELEASE"
      ;;
    bundle|aab)
      log_info "بدء بناء حزمة Android App Bundle (AAB)..."
      ./gradlew ":$APP_MODULE:bundleRelease"
      OUTPUT="$AAB_OUTPUT"
      ;;
    *)
      log_error "نوع بناء غير مدعوم: '$BUILD_TYPE'"
      echo "الخيارات المتاحة: debug, release, bundle"
      exit 1
      ;;
  esac

  echo ""
  if [[ -f "$OUTPUT" ]]; then
    log_ok "تم البناء بنجاح!"
    echo "التطبيق: $APP_DISPLAY_NAME"
    echo "ملف المخرجات: $OUTPUT"
    echo "حجم الملف: $(du -h "$OUTPUT" | cut -f1)"
    echo ""
    echo "لاختبار التطبيق على جهاز متصل:"
    echo "  ./scripts/apk-test.sh install $OUTPUT"
    echo ""
    echo "لاختبار كامل (تثبيت + تشغيل + سجلات):"
    echo "  ./scripts/apk-test.sh test $OUTPUT"
    echo ""
  else
    log_error "لم يتم العثور على ملف المخرجات في المسار المتوقع: $OUTPUT"
    exit 1
  fi
}

# ============================================================
# التنفيذ
# ============================================================
do_build