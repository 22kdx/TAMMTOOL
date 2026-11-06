#!/usr/bin/env bash
#
# check-env.sh - سكريبت فحص بيئة البناء لتطبيقات Android
# جزء من مستودع TAMMTOOL
#
# التحقق من تثبيت JDK و Android SDK و Gradle و adb و'apksigner
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
WARN=0
FAIL=0

ok()   { echo -e "${GREEN}[✓]${NC} $1"; PASS=$((PASS+1)); }
warn() { echo -e "${YELLOW}[!]${NC} $1"; WARN=$((WARN+1)); }
bad()  { echo -e "${RED}[✗]${NC} $1"; FAIL=$((FAIL+1)); }

echo "============================================="
echo " TAMMTOOL - فحص بيئة بناء تطبيقات Android"
 echo "============================================="
 echo ""

# 1. Java / JDK
if command -v java >/dev/null 2>&1; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
  if java -version 2>&1 | grep -qiE '17|21|1[7-9]|[2-9][0-9]'; then
    ok "Java JDK مثبّت: $JAVA_VERSION"
  else
    warn "Java JDK مثبت بإصدار قديم: $JAVA_VERSION (يُوصى بالإصدار 17 أو أحدث)"
  fi
else
  bad "Java JDK غير مثبت. يُرجى تثبيت JDK 17 أو أحدث."
fi

# 2. Android SDK / ANDROID_HOME
if [[ -n "${ANDROID_HOME:-}" ]] && [[ -d "$ANDROID_HOME" ]]; then
  ok "متغير ANDROID_HOME مضبط: $ANDROID_HOME"
else
  warn "متغير ANDROID_HOME غير مضبط أو المسار غير موجود."
fi

# 3. adb
if command -v adb >/dev/null 2>&1; then
  ok "adb موجود: $(adb version | head -n 1)"
else
  bad "adb غير موجود. يُرجى تثبيت Android SDK Platform-Tools وإضافته إلى PATH."
fi

# 4. apksigner
APKSIGNER_FOUND=0
if [[ -n "${ANDROID_HOME:-}" ]]; then
  while IFS= read -r -d '' f; do
    APKSIGNER_FOUND=1
    ok "apksigner موجود: $f"
    break
  done < <(find "$ANDROID_HOME/build-tools" -name apksigner -type f -print0 2>/dev/null | sort -z)
fi
if [[ "$APKSIGNER_FOUND" -eq 0 ]]; then
  bad "apksigner غير موجود. يُرجى تثبيت Android SDK Build-Tools."
fi

# 5. Gradle Wrapper
if [[ -x "./gradlew" ]]; then
  ok "Gradle Wrapper موجود في جذر المشروع."
  if ./gradlew --version >/dev/null 2>&1; then
    ok "Gradle Wrapper يعمل بشكل صحيح."
  else
    warn "Gradle Wrapper موجود لكنه يواجه خطأ عند التشغيل."
  fi
else
  warn "Gradle Wrapper غير موجود في المسار الحالي. تأكد من أنك في جذر مشروع Android."
fi

# 6. Git
if command -v git >/dev/null 2>&1; then
  ok "Git موجود: $(git --version)"
else
  warn "Git غير مثبت. يُنصح بتثبيته لإدارة الشيفرة المصدرية."
fi

echo ""
echo "============================================="
echo "النتيجة: ${GREEN}نجاح: $PASS${NC} | ${YELLOW}تحذيرات: $WARN${NC} | ${RED}فشل: $FAIL${NC}"
echo "============================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "يوجد فشل في البيئة. يُرجى إصلاح المكونات الفاشلة قبل البناء."
  exit 1
fi

if [[ "$WARN" -gt 0 ]]; then
  echo "يوجد تحذيرات. يُنصح بمعالجتها لضمان بناء سلس."
fi

echo "البيئة جاهزة لبناء تطبيقات APK."
exit 0