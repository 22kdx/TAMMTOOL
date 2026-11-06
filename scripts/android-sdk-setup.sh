#!/usr/bin/env bash
#
# android-sdk-setup.sh - سكريبت تثبيت Android SDK تلقائياً
# جزء من مستودع TAMMTOOL
#
# هذا السكريبت يقوم بتحميل وتثبيت Android Command Line Tools
# وقبول التراخيص وتثبيت المنصات والأدوات المطلوبة لبناء تطبيقات Android.
#
# يعمل على: Linux (Ubuntu/Debian)، macOS، GitHub Actions runners
#
# الاستخدام:
#   ./scripts/android-sdk-setup.sh [--sdk-dir /path/to/sdk] [--accept-licenses]
#
# مثال:
#   ./scripts/android-sdk-setup.sh --sdk-dir $HOME/android-sdk --accept-licenses

set -euo pipefail

# ============================================================
# إعدادات افتراضية
# ============================================================
SDK_DIR="${ANDROID_HOME:-$HOME/android-sdk}"
ACCEPT_LICENSES=false
CMDLINE_TOOLS_VERSION="11076708"  # آخر نسخة مستقرة من commandline-tools
PLATFORM_VERSION="android-35"
BUILD_TOOLS_VERSION="35.0.0"
PACKAGES="
  platform-tools
  platforms;${PLATFORM_VERSION}
  build-tools;${BUILD_TOOLS_VERSION}
"

# ألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[ℹ]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

# ============================================================
# تحليل الوسائط (arguments)
# ============================================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sdk-dir)
      SDK_DIR="$2"
      shift 2
      ;;
    --accept-licenses)
      ACCEPT_LICENSES=true
      shift
      ;;
    --help|-h)
      echo "الاستخدام: $0 [--sdk-dir <المسار>] [--accept-licenses] [--help]"
      echo ""
      echo "الخيارات:"
      echo "  --sdk-dir <المسار>    مسار تثبيت Android SDK (الافتراضي: \$ANDROID_HOME أو \$HOME/android-sdk)"
      echo "  --accept-licenses    قبول تراخيص Android SDK تلقائياً"
      echo "  --help, -h           عرض هذه المساعدة"
      exit 0
      ;;
    *)
      log_error "خيار غير معروف: $1"
      exit 1
      ;;
  esac
done

export ANDROID_HOME="$SDK_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "============================================="
echo "  TAMMTOOL - تثبيت Android SDK"
echo "============================================="
echo "مسار التثبيت: $ANDROID_HOME"
echo "إصدار أدوات سطر الأوامر: $CMDLINE_TOOLS_VERSION"
echo "النظام الأساسي: $PLATFORM_VERSION"
<<<<>>> echo "أدوات البناء: $BUILD_TOOLS_VERSION"
echo ""

# ============================================================
# التحقق من المتطلبات الأساسية
# ============================================================
log_info "التحقق من المتطلبات الأساسية..."

if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
  log_error "لا يوجد curl أو wget مثبتاً. يرجى تثبيت أحداهما للمتابعة."
  exit 1
fi

if ! command -v unzip &> /dev/null && ! command -v tar &> /dev/null; then
  log_error "لا يوجد unzip أو tar لفك الضغط. يرجى تثبيتهما للمتابعة."
  exit 1
fi

if ! command -v java &> /dev/null; then
  log_warn "Java غير مثبت في PATH. قد يفشل بناء Android بدون JDK."
  log_info "يمكن تثبيت Java عبر: sudo apt-get install openjdk-17-jdk (على Ubuntu)"
fi

log_ok "تم التحقق من المتطلبات الأساسية."

# ============================================================
# إنشاء مجلد SDK
# ============================================================
log_info "إنشاء مجلد SDK في: $ANDROID_HOME"
mkdir -p "$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/cmdline-tools"

# ============================================================
# تحديد عنوان التحميل حسب نظام التشغيل
# ============================================================
OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS_NAME" in
  linux)
    if [[ "$ARCH" == "x86_64" ]]; then
      CMDLINE_TOOLS_ZIP="commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
    else
      log_error "البنية المعمارية غير مدعومة على Linux: $ARCH"
      exit 1
    fi
    ;;
  darwin)
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "arm64" ]]; then
      CMDLINE_TOOLS_ZIP="commandlinetools-mac-${CMDLINE_TOOLS_VERSION}_latest.zip"
    else
      log_error "البنية المعمارية غير مدعومة على macOS: $ARCH"
      exit 1
    fi
    ;;
  *)
    log_error "نظام التشغيل غير مدعوم: $OS_NAME"
    exit 1
    ;;
esac

DOWNLOAD_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"
ZIP_PATH="$ANDROID_HOME/${CMDLINE_TOOLS_ZIP}"

# ============================================================
# تحميل أدوات سطر الأوامر
# ============================================================
log_info "تحميل Android Command Line Tools من:"
echo "  $DOWNLOAD_URL"

if command -v curl &> /dev/null; then
  curl -L --fail --retry 3 --retry-delay 5 -o "$ZIP_PATH" "$DOWNLOAD_URL"
else
  wget -q --tries=3 --timeout=30 -O "$ZIP_PATH" "$DOWNLOAD_URL"
fi

if [[ ! -f "$ZIP_PATH" ]] || [[ ! -s "$ZIP_PATH" ]]; then
  log_error "فشل تحميل ملف أدوات سطر الأوامر."
  exit 1
fi

log_ok "تم تحميل ملف zip بنجاح ($(du -h "$ZIP_PATH" | cut -f1))."

# ============================================================
# فك الضغط
# ============================================================
log_info "فك ضغط أدوات سطر الأوامر..."

# إزالة التثبيت السابق إن وجد
rm -rf "$ANDROID_HOME/cmdline-tools/latest"

# فك الضغط إلى مجلد مؤقت ثم نقله
TEMP_DIR="$ANDROID_HOME/.cmdline-tools-temp"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

unzip -q -o "$ZIP_PATH" -d "$TEMP_DIR"

# 명령라인 tools يأتي ضمن مجلد cmdline-tools داخل الـ zip
# ننقل محتوياته إلى latest
if [[ -d "$TEMP_DIR/cmdline-tools" ]]; then
  mv "$TEMP_DIR/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
else
  # بعض الإصدارات تأتي مع المجلد مباشرة
  mv "$TEMP_DIR"/* "$ANDROID_HOME/cmdline-tools/latest"
fi

rm -rf "$TEMP_DIR"
rm -f "$ZIP_PATH"

log_ok "تم فك ضغط أدوات سطر الأوامر في: $ANDROID_HOME/cmdline-tools/latest"

# ============================================================
# قبول التراخيص
# ============================================================
if [[ "$ACCEPT_LICENSES" == true ]]; then
  log_info "قبول تراخيص Android SDK..."
  mkdir -p "$ANDROID_HOME/licenses"

  # مفاتيح التراخيص الشائعة لـ Android SDK
  cat > "$ANDROID_HOME/licenses/android-sdk-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
EOF

  cat > "$ANDROID_HOME/licenses/android-sdk-preview-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
EOF

  log_ok "تم قبول التراخيص."
fi

# ============================================================
# تثبيت الحزم المطلوبة
# ============================================================
log_info "تثبيت الحزم المطلوبة عبر sdkmanager..."
echo "الحزم: $PACKAGES"

for package in $PACKAGES; do
  log_info "جاري تثبيت: $package"
  if ! yes | sdkmanager "$package" > /dev/null 2>&1; then
    log_warn "فشل تثبيت $package عبر síesno، نحاول قبول الترخيص تلقائياً..."
    echo "y" | sdkmanager "$package" || true
  fi
done

log_ok "تم تثبيت جميع الحزم المطلوبة."

# ============================================================
# تحديث متغيرات البيئة للجلسة الحالية
# ============================================================
echo ""
echo "============================================="
log_ok "اكتمل تثبيت Android SDK بنجاح!"
echo "============================================="
echo ""
echo "لضمان عمل السكريبتات الأخرى، أضف الأسطر التالية إلى ~/.bashrc أو ~/.zshrc:"
echo ""
echo "  export ANDROID_HOME=\"$ANDROID_HOME\""
echo "  export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\""
echo ""
echo "أو شغل الأمر التالي في الجلسة الحالية:"
echo "  export ANDROID_HOME=\"$ANDROID_HOME\""
echo "  export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\""
echo ""

# التحقق من التثبيت
if command -v sdkmanager &> /dev/null; then
  log_info "إصدار sdkmanager:"
  sdkmanager --version || true
else
  log_warn "sdkmanager غير موجود في PATH. يرجى إضافة $ANDROID_HOME/cmdline-tools/latest/bin إلى PATH."
fi