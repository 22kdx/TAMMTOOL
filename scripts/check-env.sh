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
# فحص الإصدار رقمياً: كان grep -E '17|21|…' يطابق أي سطر فيه «17» (مثل 11.0.17) فيمرّ JDK 11
if command -v java >/dev/null 2>&1; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
  JAVA_MAJOR=$(printf '%s\n' "$JAVA_VERSION" | awk -F. '{ if ($1 == 1) print $2; else print $1 }' | tr -dc '0-9')
  if [[ -z "${JAVA_MAJOR:-}" ]]; then
    warn "تعذّر قراءة رقم إصدار Java من: $JAVA_VERSION"
  elif (( JAVA_MAJOR >= 17 )); then
    ok "Java JDK $JAVA_MAJOR ($JAVA_VERSION) — يلبي حد AGP 8.x الأدنى (17)"
  else
    bad "Java $JAVA_MAJOR قديم مقابل Android Gradle Plugin 8.6 الذي يتطلب JDK 17+ (الموجود: $JAVA_VERSION)"
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

# 5. Gradle Wrapper — لكل مشروع على حدة (الجذر لا يحتوي gradlew أصلاً في TAMMTOOL)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIRS=()
for root in apps examples projects templates; do
  [[ -d "$PROJECT_ROOT/$root" ]] || continue
  for dir in "$PROJECT_ROOT/$root"/*/; do
    [[ -f "${dir}settings.gradle" || -f "${dir}settings.gradle.kts" ]] && APP_DIRS+=("${dir%/}")
  done
done
[[ ${#APP_DIRS[@]} -eq 0 ]] && APP_DIRS+=("$PROJECT_ROOT")

missing_wrapper=0
for app_dir in "${APP_DIRS[@]}"; do
  name="${app_dir#$PROJECT_ROOT/}"
  if [[ -x "$app_dir/gradlew" && -f "$app_dir/gradle/wrapper/gradle-wrapper.jar" ]]; then
    ok "Wrapper موجود: $name (gradlew + gradle-wrapper.jar)"
    if (cd "$app_dir" && ./gradlew --version >/dev/null 2>&1); then
      ok "Wrapper يعمل: $name"
    else
      warn "يعطّل عند التشغيل: $name — جرّب: (cd $name && ./gradlew --version)"
    fi
  else
    missing_wrapper=1
    bad "لا wrapper في $name (ينقص gradlew أو gradle-wrapper.jar) — أنشئه: ./scripts/download-gradlew.sh 8.7"
  fi
done

# 6. Git
if command -v git >/dev/null 2>&1; then
  ok "Git موجود: $(git --version)"
else
  warn "Git غير مثبت. يُنصح بتثبيته لإدارة الشيفرة المصدرية."
fi

echo ""
echo "============================================="
echo -e "النتيجة: ${GREEN}نجاح: $PASS${NC} | ${YELLOW}تحذيرات: $WARN${NC} | ${RED}فشل: $FAIL${NC}"
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