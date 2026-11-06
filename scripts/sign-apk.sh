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

# ── كلمات المرور: من البيئة، أو تفاعلياً عند وجود طرفية فقط ─────────────────
# (B3 في GAP_TO_APK.md) كان pass:… يمرَّر في سطر الأوامر فيُرى في ps/سجل CI،
# وكان read -rsp يعلّق في CI أو الأنابيب. الآن env: + رفض صريح بلا طرفية.
if [[ -z "${KEYSTORE_PASSWORD:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rsp "أدخل كلمة مرور keystore: " KEYSTORE_PASSWORD; echo ""
  else
    echo "خطأ: اضبط KEYSTORE_PASSWORD في البيئة (CI/الأنابيب بلا طرفية)." >&2
    exit 1
  fi
fi
if [[ -z "${KEY_PASSWORD:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rsp "أدخل كلمة مرور المفتاح (key password): " KEY_PASSWORD; echo ""
  else
    echo "خطأ: اضبط KEY_PASSWORD في البيئة (CI/الأنابيب بلا طرفية)." >&2
    exit 1
  fi
fi
export KEYSTORE_PASSWORD KEY_PASSWORD

# التوقيع
# التوقيع — env: بدل pass: فلا تظهر كلمات المرور في قائمة العمليات
"$APKSIGNER" sign --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" \
  --ks-pass env:KEYSTORE_PASSWORD \
  --key-pass env:KEY_PASSWORD \
  --out "$OUTPUT_APK" "$INPUT_APK"

echo ""
echo "تم التوقيع بنجاح!"
echo "ملف APK الموقّع: $OUTPUT_APK"

# التحقق من التوقيع + بصمة SHA-256 (قارنها بـ Play Console → App signing / upload key)
echo "جاري التحقق من التوقيع..."
"$APKSIGNER" verify --verbose --print-certs "$OUTPUT_APK"

# فحص المحاذاة إن وُجدت zipalign (apksigner يشترط محاذاة صحيحة في الأدوات الأقدم)
ZIPALIGN=""
if [[ -n "${ANDROID_HOME:-}" ]]; then
  ZIPALIGN="$(find "$ANDROID_HOME/build-tools" -name zipalign -type f 2>/dev/null | sort | tail -n 1 || true)"
fi
if [[ -n "${ZIPALIGN:-}" && -x "$ZIPALIGN" ]]; then
  "$ZIPALIGN" -c -v 4 "$OUTPUT_APK" >/dev/null 2>&1 \
    || echo "تحذير: الملف غير محاذى — نفّذ: zipalign -f 4 <in> $OUTPUT_APK ثم أعد التوقيع."
fi

echo ""
echo "الملف جاهز للتثبيت أو النشر على Google Play."