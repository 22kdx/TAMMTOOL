#!/usr/bin/env bash
#
# build-apk.sh - سكريبت مساعدة لبناء تطبيقات Android (APK / AAB)
# جزء من مستودع TAMMTOOL
#
# الاستخدام:
#   ./scripts/build-apk.sh [debug|release|bundle] [module]
#
# مثال:
#   ./scripts/build-apk.sh release app
#

set -euo pipefail

BUILD_TYPE="${1:-debug}"
MODULE="${2:-app}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

echo "============================================="
echo " TAMMTOOL - بناء تطبيق Android"
 echo "============================================="
 echo "نوع البناء: $BUILD_TYPE"
 echo "الوحدة: $MODULE"
 echo "المسار: $PROJECT_ROOT"
 echo ""

# التحقق من وجود Gradle Wrapper
if [[ ! -x "./gradlew" ]]; then
  echo "خطأ: ملف gradlew غير موجود في جذر المشروع."
  exit 1
fi

# التحقق من وجود متغير ANDROID_HOME
if [[ -z "${ANDROID_HOME:-}" ]]; then
  echo "تحذير: متغير البيئة ANDROID_HOME غير مضبط."
  echo "تأكد من تثبيت Android SDK وإضافته إلى PATH."
fi

case "$BUILD_TYPE" in
  debug)
    echo "بدء بناء نسخة التصحيح (Debug APK)..."
    ./gradlew ":$MODULE:assembleDebug"
    OUTPUT="app/build/outputs/apk/debug/app-debug.apk"
    ;;
  release)
    echo "بدء بناء نسخة الإصدار (Release APK)..."
    ./gradlew ":$MODULE:assembleRelease"
    OUTPUT="app/build/outputs/apk/release/app-release.apk"
    ;;
  bundle|aab)
    echo "بدء بناء حزمة Android App Bundle (AAB)..."
    ./gradlew ":$MODULE:bundleRelease"
    OUTPUT="app/build/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "خطأ: نوع بناء غير مدعوم '$BUILD_TYPE'. الخيارات المتاحة: debug, release, bundle"
    exit 1
    ;;
esac

echo ""
if [[ -f "$OUTPUT" ]]; then
  echo "تم البناء بنجاح!"
  echo "ملف المخرجات: $OUTPUT"
  echo "حجم الملف: $(du -h "$OUTPUT" | cut -f1)"
else
  echo "تحذير: لم يتم العثور على ملف المخرجات في المسار المتوقع: $OUTPUT"
  echo "تأكد من أن اسم الوحدة '$MODULE' صحيح."
fi