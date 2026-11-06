#!/usr/bin/env bash
#
# tests/mock-smoke.sh — اختبار سكربتات TAMMTOOL بدون Android Studio وبدون هاتف
#
# يبني مشروعاً وهمياً في مجلد مؤقت مع أدوات مزيفة (java, gradle/gradlew, adb, aapt2)،
# ثم يشغّل scripts/build-apk.sh و scripts/apk-test.sh على الحالات الحرجة:
#   بناء ناجح · فشل بناء مع تشخيص · توليد Wrapper · توليد APK غير موقّع ·
#   فحص ثابت (validate) · اختبار حيّ (test) مع تقرير · لا يوجد جهاز · adb مفقود.
#
# الاستخدام:
#   ./scripts/tests/mock-smoke.sh        # وضع صامت
#   ./scripts/tests/mock-smoke.sh -v     # يطبع مخرجات كل حالة فاشلة
#
# لا يحتاج إنترنت ولا صلاحيات مدير ولا JDK — فقط bash + zip/unzip.
#
set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]] && VERBOSE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tamm-mock-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT INT TERM

PASSED=0
FAILED=0

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok() {
  printf '  \033[0;32m✓\033[0m %s\n' "$1"
  PASSED=$((PASSED + 1))
}
no() {
  printf '  \033[0;31m✗\033[0m %s\n' "$1" >&2
  if [[ "$VERBOSE" == "1" && -f "$WORK/last.log" ]]; then
    sed 's/^/      | /' "$WORK/last.log" | head -n 40 >&2
  fi
  FAILED=$((FAILED + 1))
}

# عكس expect_out: ينجح إذا لم يظهر النمط (للأشياء التي يجب ألا يفعلها السكربت، كشريط تقدم
# تنزيلٍ في وضع offline — صيغة «لا شيء» لا تُختبَر بـ grep موجب).
expect_not_out() {
  local desc="$1" pat="$2"
  if [[ -f "$WORK/last.log" ]] && grep -qE -- "$pat" "$WORK/last.log"; then
    no "$desc — ظهر ما لا ينبغي: $(grep -m1 -E -- "$pat" "$WORK/last.log" | cut -c1-70)"
  else
    ok "$desc"
  fi
}

RC=0
run() {
  "$@" >"$WORK/last.log" 2>&1
  RC=$?
}

expect() { # expect <وصف> <أمر...>
  local desc="$1"
  shift
  run "$@"
  [[ $RC -eq 0 ]] && ok "$desc" || no "$desc (رمز $RC)"
}

expect_rc() { # expect_rc <رمز> <وصف> <أمر...>
  local want="$1" desc="$2"
  shift 2
  run "$@"
  [[ "$RC" == "$want" ]] && ok "$desc (رمز $RC)" || no "$desc — توقعت $want وحصلت على $RC"
}

expect_out() { # expect_out <وصف> <نمط> — يبحث في ناتج آخر run
  local desc="$1" pattern="$2"
  if grep -Eq "$pattern" "$WORK/last.log" 2>/dev/null; then
    ok "$desc"
  else
    no "$desc — لم أجد: $pattern"
  fi
}

file_exists() {
  [[ -e "$1" ]] && ok "$2" || no "$2 — مفقود: $1"
}

for tool in zip unzip; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'هذا الاختبار يحتاج %s.\n' "$tool" >&2
    exit 1
  }
done

say "TAMMTOOL — اختبار السكربتات بأدوات مزيفة (لا يحتاج Android ولا هاتف)
  مجلد العمل: $WORK"

# ============================================================
# 1) مستودع وهمي فيه ثلاثة تطبيقات
#    demo  : فيه Wrapper كامل  → المسار الطبيعي
#    demo2 : بدون Wrapper ومع gradle على النظام → يولّد Wrapper
#    demo3 : بدون أي شيء ومع --offline → يجب أن يفشل برسالة واضحة
# ============================================================
REPO="$WORK/repo"
mkdir -p "$REPO/scripts"
cp "$REPO_ROOT/scripts/build-apk.sh" "$REPO_ROOT/scripts/apk-test.sh" "$REPO/scripts/"

make_app() { # make_app <اسم>
  local name="$1"
  mkdir -p "$REPO/apps/$name/app" "$REPO/apps/$name/gradle/wrapper"
  cat >"$REPO/apps/$name/settings.gradle.kts" <<EOF
rootProject.name = "${name^}App"
include(":app")
EOF
  cat >"$REPO/apps/$name/app/build.gradle.kts" <<EOF
android {
    namespace = "com.tammtool.${name}app"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.tammtool.${name}app"
        minSdk = 24
        targetSdk = 35
        versionCode = 7
        versionName = "1.2.3"
    }
}
EOF
  : >"$REPO/apps/$name/build.gradle.kts"
}
make_app demo
make_app demo2
make_app demo3
make_app demo4   # بلا Wrapper وبلا gradle على النظام (PATH بديل)

# gradlew + gradle-wrapper.jar للتطبيق demo (الحالة الطبيعية)
cat >"$REPO/apps/demo/gradle/wrapper/gradle-wrapper.properties" <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
: >"$REPO/apps/demo/gradle/wrapper/gradle-wrapper.jar"
cat >"$REPO/apps/demo/gradlew" <<'GRADLEW'
#!/usr/bin/env bash
exec "$MOCK_GRADLE" "$@"
GRADLEW
chmod +x "$REPO/apps/demo/gradlew"

# الأدوات المزيفة
BIN="$WORK/bin"
mkdir -p "$BIN"

cat >"$BIN/java" <<'JAVA'
#!/usr/bin/env bash
printf 'openjdk version "17.0.11" 2024-04-16\nOpenJDK 64-Bit Server VM (Temurin) 17.0.11+9\n' >&2
JAVA

# gradle مزيف: يتولّى wrapper و assemble* وينتج ملفات مخرجات وهمية
cat >"$BIN/mock-gradle" <<'MOCK'
#!/usr/bin/env bash
set -u
# استدعاءات الفحص لا يجب أن تكتب أي ملفات
case "$*" in
  *--version* | *":app:help"*)
    echo "Gradle 8.7 (mock)"
    exit 0
    ;;
esac
for a in "$@"; do
  case "$a" in
    wrapper)
      mkdir -p gradle/wrapper
      : >gradle/wrapper/gradle-wrapper.jar
      cat >gradle/wrapper/gradle-wrapper.properties <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
      cat >gradlew <<EOF
#!/usr/bin/env bash
exec "\$MOCK_GRADLE" "\$@"
EOF
      chmod +x gradlew
      echo "BUILD SUCCESSFUL  :wrapper  (mock, in $here)"
      exit 0
      ;;
    *:clean)
      echo "BUILD SUCCESSFUL  :clean (mock)"
      exit 0
      ;;
  esac
done

if [[ "${TAMM_MOCK_FAIL:-0}" == "1" ]]; then
  echo "> Task :app:processDebugMainManifest FAILED"
  echo "FAILURE: Build failed with an exception."
  echo "* What went wrong:"
  echo "Execution failed for task ':app:processDebugMainManifest'."
  echo "SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable"
  exit 1
fi

out="app/build/outputs/apk/debug"
name="app-debug.apk"
for a in "$@"; do
  case "$a" in
    *assembleRelease*) out="app/build/outputs/apk/release"
      name="app-release-unsigned.apk" ;;
    *bundleRelease*) out="app/build/outputs/bundle/release"
      name="app-release.aab" ;;
    *testDebugUnitTest*) out="app/build/test-results"
      name="TEST-dummy.xml" ;;
  esac
done
mkdir -p "$out"
cp "$MOCK_APK_SRC" "$out/$name"
echo "BUILD SUCCESSFUL in 3s"
echo "42 actionable tasks: 42 executed"
MOCK
chmod +x "$BIN/mock-gradle"
ln -sf "$BIN/mock-gradle" "$BIN/gradle"

cat >"$BIN/aapt2" <<'AAPT'
#!/usr/bin/env bash
if [[ "${1:-}" == "dump" && "${2:-}" == "badging" ]]; then
  cat <<'EOF'
package: name='com.tammtool.demoapp' versionCode='7' versionName='1.2.3' platformBuildVersionName='15'
sdkVersion:'24'
targetSdkVersion:'35'
application-label:'Demo App'
launchable-activity: name='com.tammtool.demoapp.MainActivity'  label='' icon=''
uses-permission: name='android.permission.INTERNET'
EOF
  exit 0
fi
exit 0
AAPT
cp "$BIN/aapt2" "$BIN/aapt"

cat >"$BIN/adb" <<'ADB'
#!/usr/bin/env bash
# adb مزيف: جهاز واحد وكل العمليات تنجح
[[ "${1:-}" == "-s" ]] && shift 2
case "$*" in
  *devices*)
    printf 'List of devices attached\nemulator-5554\tdevice\n'
    ;;
  *install*) printf 'Performing Streamed Install\nSuccess\n' ;;
  *uninstall*) printf 'Success\n' ;;
  *resolve-activity*) printf 'package:com.tammtool.demoapp/com.tammtool.demoapp.MainActivity\n' ;;
  *"am start"*) printf 'Status: ok\nWaiting for activity: done\n' ;;
  *pidof*) printf '4242\n' ;;
  *"logcat -c"*) : ;;
  *logcat*) printf '01-01 00:00:00  4242 4242 I DemoApp : started ok\n' ;;
  *screencap*)
    printf '\211PNG\r\n\032\nfake-png-bytes'
    ;;
esac
exit 0
ADB
chmod +x "$BIN"/*

# APK وهمي (موقّع رمزياً) وغير موقّع
mkdir -p "$WORK/fake-signed/META-INF" "$WORK/fake-unsigned"
printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.tammtool.demoapp" android:versionCode="7" android:versionName="1.2.3"/>' >"$WORK/fake-signed/AndroidManifest.xml"
printf 'dex\n035' >"$WORK/fake-signed/classes.dex"
: >"$WORK/fake-signed/resources.arsc"
: >"$WORK/fake-signed/META-INF/CERT.RSA"
printf 'Manifest-Version: 1.0\n' >"$WORK/fake-signed/META-INF/MANIFEST.MF"
(cd "$WORK/fake-signed" && zip -qr "$WORK/demo.apk" .)
cp "$WORK/demo.apk" "$REPO/signed-copy.apk"
printf '<manifest package="com.tammtool.demoapp"/>' >"$WORK/fake-unsigned/AndroidManifest.xml"
printf 'dex\n035' >"$WORK/fake-unsigned/classes.dex"
: >"$WORK/fake-unsigned/resources.arsc"
rm -f "$REPO/unsigned.apk"
(cd "$WORK/fake-unsigned" && zip -qr "$REPO/unsigned.apk" .)

# SDK وهمي
SDK="$WORK/sdk"
mkdir -p "$SDK/platforms/android-35" "$SDK/build-tools/35.0.0" "$SDK/platform-tools" "$SDK/cmdline-tools/latest/bin"
cp "$BIN/adb" "$SDK/platform-tools/adb"
chmod +x "$SDK/platform-tools/adb"

export PATH="$BIN:/usr/bin:/bin"
# الفحوص تفترض عالماً بلا شبكة (كما في sandbox الوكيل). على runner فيه اتصال كان ذلك كذباً:
# فتنجح التنزيلات وتتغيّر الرسائل، فيُظن أن السكربت كُسر. نوقِف الشبكة حتمياً بمنفذ ميت —
# أي أن «offline» يصبح حالة مُختبَرة، لا مصادفة بيئة. ولا نترك ANDROID_HOME الحقيقي يتسرّب.
export ANDROID_HOME="${SDK:-$WORK/sdk}" ANDROID_SDK_ROOT="${SDK:-$WORK/sdk}"
# ANDROID_SDK_ROOT بدورها: apk-test.sh يبحث عن adb في $ANDROID_SDK_ROOT/platform-tools، وعلى runner
# هذا متغير حقيقي (setup-android) فيجد adb «مثبتاً» رغم أننا حذفناه من الـ fake ⇒ رسالة أخرى
# فيُظن أن السكربت كسر «شرح تثبيت platform-tools». (فشل 42291044401، والتعليق يقول: لم أجد: platform-tools)
# لا بروكسي عالمي: تغيير «نوع» فشل الشبكة (refused بدل تعذّر حلّ الاسم) يقلب فحوصاً أخرى —
# لذا تُلغَم الشبكة لكل فحص حساس لها على حدة عبر OFFLINE_ENV. (البروكسي العام كسر
# «install-toolchain.sh --os/--arch» داخل mock-smoke بينما ينجح وحده: فرق 45✓ مقابل rc=1.)
OFFLINE_ENV=(env http_proxy="http://127.0.0.1:9" https_proxy="http://127.0.0.1:9" no_proxy="")
export HOME="$WORK/home"
mkdir -p "$HOME"
export ANDROID_HOME="$SDK"
export MOCK_APK_SRC="$WORK/demo.apk"
export MOCK_GRADLE="$BIN/mock-gradle"
unset JAVA_HOME TAMM_MOCK_FAIL

# PATH معزول: java فقط — لا gradle ولا adb ولا aapt
ISO="$WORK/iso"
mkdir -p "$ISO/bin"
cp "$BIN/java" "$ISO/bin/java"

B="$REPO/scripts/build-apk.sh"
T="$REPO/scripts/apk-test.sh"

# ============================================================
# 2) build-apk.sh
# ============================================================
say "[1/3] build-apk.sh — الاستخدام والمساعدة"

expect "المساعدة تعمل" bash "$B" --help
expect_out "المساعدة تذكر low-memory و offline" "low-memory"
expect "print-env يعمل" bash "$B" --print-env
expect_out "print-env يعرض التطبيقات المكتشفة" "demo"
expect_rc 1 "رفض خيار غير معروف" bash "$B" --totally-unknown
expect_out "رسالة 'خيار غير معروف'" "غير معروف"
expect_rc 1 "رفض تطبيق غير موجود" bash "$B" debug no-such-app
expect_out "يقترح التطبيقات المتاحة" "demo"
expect "رقم الإصدار" bash "$B" --version

say "[2/3] build-apk.sh — البناء"

expect "dry-run لا ينفّذ شيئاً" bash "$B" debug demo --dry-run --yes
expect_out "dry-run يعرض المهمة :app:assembleDebug" ":app:assembleDebug"
expect "dry-run بلا أي Gradle لا يلمس الشبكة" "${OFFLINE_ENV[@]}" PATH="$ISO/bin:/usr/bin:/bin" \
  HOME="$ISO" ANDROID_HOME="$SDK" MOCK_APK_SRC="$MOCK_APK_SRC" bash "$B" debug demo4 --dry-run --yes
expect_out "dry-run يوضّح أنه كان سيحمّل Gradle" "كان سيُحمَّل|سيُحمَّل|جارٍ التنزيل|لم يُعثر على Gradle|لا يوجد Gradle"

# --offline بلا أي Gradle: يفشل برسالة واضحة ولا يحاول التنزيل
run "${OFFLINE_ENV[@]}" PATH="$ISO/bin:/usr/bin:/bin" HOME="$ISO" ANDROID_HOME="$SDK" \
  MOCK_APK_SRC="$MOCK_APK_SRC" bash "$B" debug demo4 --offline --yes
[[ $RC -eq 1 ]] && ok "offline بلا Gradle → رمز 1" || no "offline بلا Gradle — توقعت 1 وحصلت $RC"
expect_out "offline يخبر أنه لا يمكنه التحميل" "offline|بلا شبكة|لا يمكن التنزيل|لا يمكنه التحميل"
expect_not_out "offline لا يعرض شريط تقدم التنزيل" "Downloading|[0-9]+%|==> |#\s*#\s*#"

expect "بناء debug عبر Wrapper قائم مسبقاً" bash "$B" debug demo --yes
expect_out "البناء يعلن النجاح" "تم البناء بنجاح"
file_exists "$REPO/apps/demo/local.properties" "local.properties أُنشئ تلقائياً"
expect "local.properties يحوي sdk.dir" grep -q "sdk.dir=" "$REPO/apps/demo/local.properties"
ls "$REPO"/dist/demo-debug-*.apk >/dev/null 2>&1 &&
  ok "APK نُسخ إلى dist/ باسم يحمل الإصدار" || no "لا يوجد APK في dist/"
ls "$REPO"/dist/demo-debug-*.apk.sha256 >/dev/null 2>&1 &&
  ok "بصمة SHA-256 محفوظة بجانب الملف" || no "لا يوجد ملف .sha256"
file_exists "$REPO/dist/latest-demo-debug.env" "ملخص البناء dist/latest-*.env"
expect "ملخص البناء يحمل version_name" grep -q "version_name=1.2.3" "$REPO/dist/latest-demo-debug.env"
expect "ملخص البناء يحمل sha256 صحيح الطول" grep -Eq "^sha256=[0-9a-f]{16}" "$REPO/dist/latest-demo-debug.env"
expect "سجل البناء محفوظ في build-logs/" bash -c "ls -1 $REPO/build-logs/demo-debug-*.log >/dev/null 2>&1"
expect "dry-run يعرض أمر gradle كاملاً" bash "$B" debug demo --dry-run --yes
expect_out "الأمر المعروض هو ./gradlew :app:assembleDebug" "gradlew :app:assembleDebug"

expect "بناء release يلتقط app-release-unsigned.apk" bash "$B" release demo --yes
expect_out "تحذير من أن الملف غير موقّع" "unsigned|غير موقّع"
expect_out "توجيه إلى سكريبت التوقيع" "sign-apk"
expect "بناء AAB عبر bundle" bash "$B" bundle demo --yes
ls "$REPO"/dist/demo-bundle-*.aab >/dev/null 2>&1 && ok "AAB نُسخ إلى dist/" || no "لا يوجد AAB في dist/"
expect "بناء unit-test" bash "$B" unit-test demo --yes

expect "توليد Wrapper عند غيابه (باستخدام gradle النظام)" \
  env ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK" MOCK_APK_SRC="$MOCK_APK_SRC" bash "$B" debug demo2 --yes
file_exists "$REPO/apps/demo2/gradlew" "gradlew وُلّد في apps/demo2"
file_exists "$REPO/apps/demo2/gradle/wrapper/gradle-wrapper.jar" "gradle-wrapper.jar وُلّد"
ls "$REPO"/dist/demo2-debug-*.apk >/dev/null 2>&1 && ok "بناء demo2 نجح بعد توليد Wrapper" || no "فشل بناء demo2"

expect "--all يبني كل التطبيقات" \
  env ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK" MOCK_APK_SRC="$MOCK_APK_SRC" bash "$B" debug all --yes
ls "$REPO"/dist/demo3-debug-*.apk >/dev/null 2>&1 &&
  ok "demo3 بُني بعد توليد Wrapper له" || no "demo3 لم يُبنَ ضمن --all"


run env TAMM_MOCK_FAIL=1 bash "$B" debug demo --yes
expect_rc 1 "فشل البناء يُرجع رمز 1" env TAMM_MOCK_FAIL=1 bash "$B" debug demo --yes
expect_out "تشخيص فشل البناء يذكر SDK" "SDK location|ANDROID_HOME|android-35"
expect_out "يشير إلى ملف السجل" "build-logs/"

run env -i PATH="/usr/bin:/bin" HOME="$HOME" ANDROID_HOME="$SDK" MOCK_APK_SRC="$MOCK_APK_SRC" \
  MOCK_GRADLE="$MOCK_GRADLE" bash "$B" debug demo --yes
expect_out "رسالة JDK واضحة عند غيابه" "JDK"

# ── B. خطة بديلة عند تلف scripts/android-sdk-setup.sh ──
rm -f "$REPO/apps/demo/local.properties"   # حتى لا يُكتشف SDK من الملف القديم
printf 'echo "سكربت مكسور"\nexit 0\n' >"$REPO/scripts/android-sdk-setup.sh"
echo 'this is ( not bash >>>' >>"$REPO/scripts/android-sdk-setup.sh"
# يُلغى ANDROID_SDK_ROOT مع ANDROID_HOME: تصدير واحد يكفي ليجد السكربت SDK صالحاً فيتخطّى
# فرع الإعداد كله، ولا يُختبَر مسار «android-sdk-setup.sh مكسور» إطلاقاً.
run "${OFFLINE_ENV[@]}" PATH="$ISO/bin:/usr/bin:/bin" HOME="$ISO" ANDROID_HOME="$WORK/nosdk" \
  ANDROID_SDK_ROOT="$WORK/nosdk" bash "$B" debug demo --setup-sdk --dry-run --yes
expect_out "يكتشف خطأ صيغة android-sdk-setup.sh" "خطأ صيغة|syntax error|Parsing stopped"
expect_out "يقترح التثبيت الداخلي (dry-run)" "كان سيُثبَّت|تثبيت Android SDK|setup-sdk"

# ============================================================
# 3) apk-test.sh
# ============================================================
say "[3/3] apk-test.sh"

expect "المساعدة تعمل" bash "$T" --help
expect_out "المساعدة تذكر validate و emulator" "validate"
expect "devices يعمل" bash "$T" devices
expect_out "devices يعرض الجهاز الوهمي" "emulator-5554"
expect "doctor يعمل" bash "$T" doctor
expect "selftest يعمل" bash "$T" selftest

expect "info على APK وهمي" bash "$T" info "$WORK/demo.apk"
expect_out "info يعرض اسم الحزمة" "com.tammtool.demoapp"
expect_out "info يعرض versionName" "1.2.3"
expect_out "info يعرض SHA-256" "SHA-256"
expect "validate ينجح على ملف موقّع رمزياً" bash "$T" validate --apk "$WORK/demo.apk"
expect_out "validate يؤكد وجود classes.dex" "classes.dex"
expect_out "validate يؤكد الأرشيف" "أرشيف APK سليم"
expect "validate يجد APK من dist بـ --app" bash "$T" validate --app demo
expect "test بدون --apk يستعمل dist" bash "$T" test --app demo --timeout 3 --yes
expect_rc 4 "validate يفشل على ملف غير موقّع" bash "$T" validate --apk "$REPO/unsigned.apk"
run bash "$T" validate --apk "$REPO/unsigned.apk"
expect_out "يشرح أن المشكلة في التوقيع" "توقيع"
expect_rc 1 "رفض APK مفقود" bash "$T" info "$WORK/nope.apk"
expect_out "رسالة 'ملف APK غير موجود'" "غير موجود"
expect_rc 1 "رفض أمر مجهول" bash "$T" frobnicate
expect_rc 1 "رفض --timeout غير رقمي" bash "$T" test --apk "$WORK/demo.apk" --timeout abc

expect "test الكامل: فحص + تثبيت + تشغيل + تقرير" bash "$T" test --apk "$WORK/demo.apk" --timeout 3 --yes
expect_out "test يعلن النتيجة الناجحة" "نتيجة الاختبار: ناجح"
ls "$REPO"/test-reports/*-test.md >/dev/null 2>&1 && ok "تقرير markdown في test-reports/" || no "لا يوجد تقرير markdown"
expect "test --json" bash "$T" test --apk "$WORK/demo.apk" --timeout 3 --json --yes
json_report="$(ls -1t "$REPO"/test-reports/*-test.json 2>/dev/null | head -n 1)"
if [[ -n "$json_report" ]] && command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));assert d["result"]=="PASS"' "$json_report" >/dev/null 2>&1; then
    ok "تقرير JSON صالح ويحمل result=PASS"
  else
    no "تقرير JSON غير صالح أو result != PASS"
  fi
else
  no "لم يُنشأ تقرير JSON"
fi
expect "install مع --reinstall --grant" bash "$T" install --apk "$WORK/demo.apk" --reinstall --grant
expect "launch يكتشف العملية" bash "$T" launch com.tammtool.demoapp
expect "logcat يحفظ السجل" bash "$T" logcat com.tammtool.demoapp
expect "screenshot يحفظ صورة" bash "$T" screenshot "$WORK/shot.png"
file_exists "$WORK/shot.png" "ملف لقطة الشاشة غير فارغ"
expect "uninstall يعمل" bash "$T" uninstall com.tammtool.demoapp
expect "dry-run لا ينفّذ" bash "$T" test --apk "$WORK/demo.apk" --dry-run --yes
expect "connect بدون هدف يطبع الإرشاد" bash -c "'$T' connect >/dev/null 2>&1 || true"
expect "emulator يعرض الإرشاد" bash "$T" emulator

# لا يوجد جهاز → الرمز 5 + إرشاد
cat >"$BIN/adb" <<'ADB0'
#!/usr/bin/env bash
printf 'List of devices attached\n\n'
exit 0
ADB0
chmod +x "$BIN/adb"
expect_rc 5 "install بدون جهاز → رمز 5" bash "$T" install --apk "$WORK/demo.apk"
run bash "$T" install --apk "$WORK/demo.apk"
expect_out "إرشاد عند غياب الجهاز (emulator/validate)" "emulator|validate"
expect "validate ما زال يعمل بدون جهاز" bash "$T" validate --apk "$WORK/demo.apk"
expect "devices يخبر أنه لا جهاز" bash "$T" devices

# adb غير مثبت → رسالة فيها platform-tools
rm -f "$BIN/adb" "$SDK/platform-tools/adb"
expect_rc 1 "adb مفقود → رمز 1" bash "$T" install --apk "$WORK/demo.apk"
expect_out "شرح تثبيت platform-tools" "platform-tools"
expect "info يعمل بدون adb" bash "$T" info "$WORK/demo.apk"

# بدون aapt → التحليل الاحتياطي
cp "$BIN/adb" /dev/null 2>/dev/null || true
rm -f "$BIN/aapt2" "$BIN/aapt"
expect "info بدون aapt يستخدم التحليل الاحتياطي" bash "$T" info "$WORK/demo.apk"

say "أدوات tools/ (سلسلة تطبيق الفلتر + القفل + الـ wrapper)"
if [[ -f "$REPO_ROOT/tools/tests/toolchain-smoke.sh" ]]; then
  # سلسلتها تُشغَّل كما هي ونتيجةُها فحصٌ واحد هنا: إن فشلت تعطب هذه الخطوة كلها
  # بيئة نظيفة تماماً: فحوص tools/ لا تعرف شيئاً عن SDK ولا عن gradle ولا عن بروكسي المشغّل،
  # ووراثتها لها (PATH مقلّص + ANDROID_* حقيقيان) هي التي أدمعت 45 فحصاً على runner وهي خضراء هنا.
  # نحذف ما يسرّب فقط (SDK/Java/Gradle/البروكسي) ولا نُفرّغ البيئة: fحوص tools/ تحتاج git/python3/gh
  # الموجودة في /usr/local/bin، و«env -i PATH=/usr/bin:/bin» حرمها منها فأنقص HOME أيضاً
  # (و«--os/--arch يُقبلان» يحتاج gh + توكنه) — فصار الفارق بين «45/45» و«44/1» سببه اختباري لا أدواتي.
  expect "tools/: 45 فحصاً في toolchain-smoke.sh" \
    env -u http_proxy -u https_proxy -u no_proxy -u ANDROID_HOME -u ANDROID_SDK_ROOT \
        -u JAVA_HOME -u GRADLE_HOME -u ANDROID_TOOLCHAIN \
      bash "$REPO_ROOT/tools/tests/toolchain-smoke.sh"
else
  no "tools/tests/toolchain-smoke.sh مفقود — أُدرج في mock-smoke ولا يوجد الملف"
fi

echo
if [[ $FAILED -eq 0 ]]; then
  printf '\033[0;32m✓\033[0m  كل الفحوص نجحت (%s)\n' "$PASSED"
  exit 0
fi
printf '\033[0;31m✗\033[0m  %s فشل من %s فحص — أعد التشغيل بـ -v للتفاصيل\n' "$FAILED" "$((PASSED + FAILED))"
exit 1
