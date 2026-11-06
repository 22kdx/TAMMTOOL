#!/usr/bin/env bash
#
# apk-test.sh - سكريبت اختبار وعرض تطبيقات Android APK
# جزء من مستودع TAMMTOOL
#
# هذا السكريبت يسمح بـ:
#   1. عرض معلومات ملف APK (اسم الحزمة، الإصدار، الحجم، الأيقونات)
#   2. تثبيت APK على جهاز متصل عبر ADB
#   3. تشغيل التطبيق بعد التثبيت
#   4. capturar لقطات شاشة من الجهاز
#   5. عرض سجلات التطبيق (logcat)
#
# الاستخدام:
#   ./scripts/apk-test.sh [command] [options]
#
# الأوامر:
#   info <apk-file>           عرض معلومات ملف APK
#   install <apk-file>        تثبيت APK على الجهاز المتصل
#   launch <package-name>     تشغيل التطبيق على الجهاز
#   uninstall <package-name>  إزالة التطبيق من الجهاز
#   logcat <package-name>     عرض سجلات التطبيق
#   screenshot <file>         capturar لقطة شاشة وحفظها في ملف
#   devices                   عرض الأجهزة المتصلة
#   test <apk-file>           تثبيت + تشغيل + عرض سجلات (اختبار كامل)
#
# مثال:
#   ./scripts/apk-test.sh test apps/marketer/app/build/outputs/apk/debug/app-debug.apk

set -euo pipefail

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
# التحقق من وجود ADB
# ============================================================
check_adb() {
  if ! command -v adb &> /dev/null; then
    log_error "ADB غير مثبت أو غير موجود في PATH."
    log_info "لإثبيت ADB على Ubuntu/Debian: sudo apt-get install android-tools-adb"
    log_info "أو أضف $ANDROID_HOME/platform-tools إلى PATH"
    exit 1
  fi
}

# ============================================================
# التحقق من وجود أجهزة متصلة
# ============================================================
check_device() {
  check_adb
  local device_count
  device_count=$(adb devices 2>/dev/null | grep -c "device$" || true)
  if [[ "$device_count" -eq 0 ]]; then
    log_error "لا يوجد أي جهاز Android متصل عبر ADB."
    log_info "تأكد من:"
    echo "  1. تشغيل خيار تصحيح USB (USB Debugging) على الجهاز"
    echo "  2. توصيل الجهاز عبر كابل USB"
    echo "  3. تشغيل محاكي Android إن لم يكن هناك جهاز فعلي"
    echo ""
    adb devices 2>/dev/null || true
    exit 1
  fi
  log_ok "تم العثور على $device_count جهاز/أجهزة متصلة."
  adb devices
}

# ============================================================
# عرض معلومات APK
# ============================================================
cmd_info() {
  local apk_file="$1"

  if [[ -z "$apk_file" ]]; then
    log_error "يرجى تحديد مسار ملف APK."
    echo "الاستخدام: $0 info <apk-file>"
    exit 1
  fi

  if [[ ! -f "$apk_file" ]]; then
    log_error "ملف APK غير موجود: $apk_file"
    exit 1
  fi

  echo "============================================="
  echo "  معلومات ملف APK"
  echo "============================================="
  echo "الملف: $apk_file"
  echo "الحجم: $(du -h "$apk_file" | cut -f1)"
  echo ""

  # محاولة استخدام aapt إذا كان متاحاً
  if command -v aapt &> /dev/null; then
    echo "--- تفاصيل الحزمة (via aapt) ---"
    aapt dump badging "$apk_file" 2>/dev/null | head -20 || true
    echo ""
  else
    log_warn "aapt غير متاح. لا يمكن عرض تفاصيل الحزمة بدقة."
    log_info "لإثبيت aapt: sudo apt-get install android-sdk-platform-tools (على Ubuntu)"
  fi

  # محاولة استخراج اسم الحزمة من manifest باستخدام strings إذا كان aapt غير متاح
  if ! command -v aapt &> /dev/null; then
    echo "--- محاولة استخراج معلومات أساسية ---"
    strings "$apk_file" 2>/dev/null | grep -oP 'package="[^"]+"' | head -3 || true
    strings "$apk_file" 2>/dev/null | grep -oP 'versionCode="[^"]+"' | head -3 || true
    strings "$apk_file" 2>/dev/null | grep -oP 'versionName="[^"]+"' | head -3 || true
  fi

  echo ""
  echo "لعرض تفاصيل كاملة، تأكد من تثبيت Android SDK Build Tools."
}

# ============================================================
# تثبيت APK
# ============================================================
cmd_install() {
  local apk_file="$1"

  if [[ -z "$apk_file" ]]; then
    log_error "يرجى تحديد مسار ملف APK."
    echo "الاستخدام: $0 install <apk-file>"
    exit 1
  fi

  if [[ ! -f "$apk_file" ]]; then
    log_error "ملف APK غير موجود: $apk_file"
    exit 1
  fi

  check_device

  log_info "جاري تثبيت APK: $apk_file"
  adb install -r "$apk_file"

  log_ok "تم تثبيت التطبيق بنجاح."
}

# ============================================================
# تشغيل التطبيق
# ============================================================
cmd_launch() {
  local package_name="$1"

  if [[ -z "$package_name" ]]; then
    log_error "يرجى تحديد اسم الحزمة."
    echo "الاستخدام: $0 launch <package-name>"
    echo "مثال: $0 launch com.tammtool.marketerapp"
    exit 1
  fi

  check_device

  log_info "جاري تشغيل التطبيق: $package_name"
  adb shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 2>/dev/null || \
    adb shell am start -n "$package_name"/.MainActivity 2>/dev/null || \
    adb shell am start -n "$package_name"/.MainActivity 2>/dev/null || true

  log_ok "تم إرسال أمر التشغيل للتطبيق."
}

# ============================================================
# إزالة التطبيق
# ============================================================
cmd_uninstall() {
  local package_name="$1"

  if [[ -z "$package_name" ]]; then
    log_error "يرجى تحديد اسم الحزمة."
    echo "الاستخدام: $0 uninstall <package-name>"
    exit 1
  fi

  check_device

  log_info "جاري إزالة التطبيق: $package_name"
  adb uninstall "$package_name" || true

  log_ok "تمت عملية الإزالة (إن كان التطبيق مثبتاً)."
}

# ============================================================
# عرض السجلات
# ============================================================
cmd_logcat() {
  local package_name="$1"

  if [[ -z "$package_name" ]]; then
    log_error "يرجى تحديد اسم الحزمة."
    echo "الاستخدام: $0 logcat <package-name>"
    echo "مثال: $0 logcat com.tammtool.marketerapp"
    exit 1
  fi

  check_device

  log_info "عرض سجلات التطبيق: $package_name (اضغط Ctrl+C للإيقاف)"
  adb logcat --pid=$(adb shell pidof "$package_name" | tr -d '[:space:]') 2>/dev/null || \
    adb logcat | grep "$package_name" || true
}

# ============================================================
# لقطة شاشة
# ============================================================
cmd_screenshot() {
  local output_file="$1"

  if [[ -z "$output_file" ]]; then
    output_file="screenshot-$(date +%Y%m%d-%H%M%S).png"
  fi

  check_device

  log_info "ت capturar لقطة شاشة وحفظها في: $output_file"
  adb exec-out screencap -p > "$output_file"

  if [[ -f "$output_file" ]]; then
    log_ok "تم حفظ لقطة الشاشة: $output_file ($(du -h "$output_file" | cut -f1))"
  else
    log_error "فشل حفظ لقطة الشاشة."
    exit 1
  fi
}

# ============================================================
# عرض الأجهزة المتصلة
# ============================================================
cmd_devices() {
  check_adb
  echo "الأجهزة المتصلة عبر ADB:"
  echo "------------------------"
  adb devices
}

# ============================================================
# اختبار كامل (تثبيت + تشغيل + سجلات)
# ============================================================
cmd_test() {
  local apk_file="$1"

  if [[ -z "$apk_file" ]]; then
    log_error "يرجى تحديد مسار ملف APK."
    echo "الاستخدام: $0 test <apk-file>"
    exit 1
  fi

  if [[ ! -f "$apk_file" ]]; then
    log_error "ملف APK غير موجود: $apk_file"
    exit 1
  fi

  echo "============================================="
  echo "  اختبار تطبيق APK"
  echo "============================================="
  echo ""

  # الخطوة 1: عرض معلومات
  log_info "الخطوة 1: عرض معلومات APK"
  cmd_info "$apk_file"
  echo ""

  # الخطوة 2: إزالة الإصدار القديم إن وجد
  log_info "الخطوة 2: إزالة الإصدار السابق (إن وجد)"
  adb uninstall com.tammtool.marketerapp 2>/dev/null || true
  adb uninstall com.tammtool.ordersapp 2>/dev/null || true
  echo ""

  # الخطوة 3: التثبيت
  log_info "الخطوة 3: تثبيت APK"
  cmd_install "$apk_file"
  echo ""

  # الخطوة 4: التشغيل
  log_info "الخطوة 4: تشغيل التطبيق"
  cmd_launch "com.tammtool.marketerapp"
  echo ""

  # الخطوة 5: عرض السجلات لمدة 10 ثوانٍ
  log_info "الخطوة 5: عرض سجلات التطبيق لمدة 15 ثانية..."
  timeout 15 adb logcat | grep -E "com.tammtool|AndroidRuntime|FATAL|Exception" || true
  echo ""

  log_ok "اكتمل الاختبار بنجاح."
}

# ============================================================
# النقطة الرئيسية
# ============================================================
COMMAND="${1:-help}"

case "$COMMAND" in
  info)
    cmd_info "${2:-}"
    ;;
  install)
    cmd_install "${2:-}"
    ;;
  launch)
    cmd_launch "${2:-}"
    ;;
  uninstall)
    cmd_uninstall "${2:-}"
    ;;
  logcat)
    cmd_logcat "${2:-}"
    ;;
  screenshot)
    cmd_screenshot "${2:-}"
    ;;
  devices)
    cmd_devices
    ;;
  test)
    cmd_test "${2:-}"
    ;;
  help|--help|-h|*)
    echo "============================================="
    echo "  TAMMTOOL - اختبار وعرض تطبيقات APK"
    echo "============================================="
    echo ""
    echo "الاستخدام: $0 <command> [options]"
    echo ""
    echo "الأوامر المتاحة:"
    echo "  info <apk-file>      عرض معلومات ملف APK"
    echo "  install <apk-file>   تثبيت APK على الجهاز المتصل"
    echo "  launch <pkg>         تشغيل التطبيق على الجهاز"
    echo "  uninstall <pkg>      إزالة التطبيق من الجهاز"
    echo "  logcat <pkg>         عرض سجلات التطبيق"
    echo "  screenshot <file>    capturar لقطة شاشة"
    echo "  devices              عرض الأجهزة المتصلة"
    echo "  test <apk-file>      اختبار كامل (تثبيت + تشغيل + سجلات)"
    echo ""
    echo "مثال:"
    echo "  $0 test apps/marketer/app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    ;;
esac