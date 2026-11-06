#!/usr/bin/env bash
#
# sign-apk.sh - سكريبت مساعدة لتوقيع ملف APK باستخدام apksigner
# جزء من مستودع TAMMTOOL
#
# الاستخدام:
#   ./scripts/sign-apk.sh <input-apk> <keystore> <key-alias> [output-apk]
#
# مثال:
#   ./scripts/sign-apk.sh app-release-unsigned.apk keystore/release-keystore.jks release-key app-release.apk
#

set -euo pipefail

INPUT_APK="${1:?يُرجى تحديد ملف APK المدخل (مثلاً app-release-unsigned.apk)}"
KEYSTORE="${2:?يُرجى تحديد ملف keystore (مثلاً keystore/release-keystore.jks)}"
KEY_ALIAS="${3:?يُرجى تحديد اسم المفتاح (key alias) (مثلاً release-key)}"
OUTPUT_APK="${4:-${INPUT_APK%.apk}-signed.apk}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ ! -f "$INPUT_APK" ]]; then
  echo "خطأ: ملف APK غير موجود: $INPUT_APK"
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "خطأ: ملف keystore غير موجود: $KEYSTORE"
  exit 1
fi

# البحث عن apksigner في build-tools
APKSIGNER=""
if [[ -n "${ANDROID_HOME:-}" ]]; then
  APKSIGNER=$(find "$ANDROID_HOME/build-tools" -name apksigner -type f 2>/dev/null | sort | tail -n 1 || true)
fi

if [[ -z "$APKSIGNER" ]]; then
  echo "خطأ: لم يتم العثور على أداة apksigner. تأكد من تثبيت Android SDK Build-Tools."
  exit 1
fi

echo "============================================="
echo " TAMMTOOL - توقيع ملف APK"
 echo "============================================="
 echo "ملف المدخل:  $INPUT_APK"
 echo "ملف keystore: $KEYSTORE"
 echo "اسم المفتاح:  $KEY_ALIAS"
 echo "ملف المخرج:   $OUTPUT_APK"
 echo "الأداة:        $APKSIGNER"
 echo ""

# طلب كلمة المرور بشكل آمن إذا لم تكن مضبوطة كمتغير بيئة
if [[ -z "${KEYSTORE_PASSWORD:-}" ]]; then
  read -rsp "أدخل كلمة مرور keystore: " KEYSTORE_PASSWORD
  echo ""
fi
if [[ -z "${KEY_PASSWORD:-}" ]]; then
  read -rsp "أدخل كلمة مرور المفتاح (key password): " KEY_PASSWORD
  echo ""
fi

# التوقيع
"$APKSIGNER" sign --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" \
  --ks-pass "pass:$KEYSTORE_PASSWORD" \
  --key-pass "pass:$KEY_PASSWORD" \
  --out "$OUTPUT_APK" "$INPUT_APK"

echo ""
echo "تم التوقيع بنجاح!"
echo "ملف APK الموقّع: $OUTPUT_APK"

# التحقق من التوقيع
echo "جاري التحقق من التوقيع..."
"$APKSIGNER" verify --verbose "$OUTPUT_APK"

echo ""
echo "الملف جاهز للتثبيت أو النشر على Google Play."