# سكريبتات البناء والاختبار — TAMMTOOL

هذا المجلد يحتوي على سكريبتات مساعدة لبناء واختبار تطبيقات Android (APK) في مستودع TAMMTOOL.

## الملفات المتاحة

| الملف | الغرض |
|------|------|
| `android-sdk-setup.sh` | تثبيت Android SDK تلقائياً (Command Line Tools، التراخيص، المنصات، أدوات البناء) |
| `build-apk.sh` | بناء تطبيقات Android (Debug/Release APK أو AAB) للتطبيقين: `marketer` و `orders-delivery` |
| `apk-test.sh` | اختبار وعرض ملفات APK (معلومات، تثبيت، تشغيل، سجلات، لقطات شاشة) |
| `check-env.sh` | التحقق من بيئة التطوير (JDK، SDK، ADB، Gradle) |
| `sign-apk.sh` | توقيع ملفات APK/App Bundle للمتجر |

---

## 1. android-sdk-setup.sh — تثبيت Android SDK

يستخدم هذا السكريبت لتحميل وتثبيت Android Command Line Tools من خوادم جوجل مباشرة، وهو الحل لمشكلة فشل GitHub Actions في تثبيت SDK عبر الإجراء الجاهز `android-actions/setup-android@v3`.

### التشغيل اليدوي

```bash
./scripts/android-sdk-setup.sh --sdk-dir $HOME/android-sdk --accept-licenses
```

### المتغيرات البيئية التي يضبطها

```bash
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

### الحزم التي يثبتها

- `platform-tools`
- `platforms;android-35`
- `build-tools;35.0.0`

---

## 2. build-apk.sh — بناء APK / AAB

يدعم بناء التطبيقين المتاحين في المستودع:

```bash
# بناء نسخة تصحيح لتطبيق المسوق (الافتراضي)
./scripts/build-apk.sh debug marketer

# بناء نسخة إصدار للتطبيق الرئيسي
./scripts/build-apk.sh release orders-delivery

# بناء حزمة App Bundle (AAB)
./scripts/build-apk.sh bundle marketer
```

### المخرجات

- **Debug APK**: `apps/<app>/app/build/outputs/apk/debug/app-debug.apk`
- **Release APK**: `apps/<app>/app/build/outputs/apk/release/app-release.apk`
- **AAB**: `apps/<app>/app/build/outputs/bundle/release/app-release.aab`

---

## 3. apk-test.sh — اختبار وعرض APK

سكريبت شامل للتعامل مع ملفات APK على أجهزة Android المتصلة عبر ADB.

### الأوامر المتاحة

```bash
# عرض معلومات ملف APK
./scripts/apk-test.sh info apps/marketer/app/build/outputs/apk/debug/app-debug.apk

# تثبيت APK على الجهاز المتصل
./scripts/apk-test.sh install apps/marketer/app/build/outputs/apk/debug/app-debug.apk

# تشغيل التطبيق بعد التثبيت
./scripts/apk-test.sh launch com.tammtool.marketerapp

# إزالة التطبيق من الجهاز
./scripts/apk-test.sh uninstall com.tammtool.marketerapp

# عرض سجلات التطبيق (logcat)
./scripts/apk-test.sh logcat com.tammtool.marketerapp

# capturar لقطة شاشة من الجهاز
./scripts/apk-test.sh screenshot screenshot.png

# عرض الأجهزة المتصلة
./scripts/apk-test.sh devices

# اختبار كامل: تثبيت + تشغيل + عرض سجلات
./scripts/apk-test.sh test apps/marketer/app/build/outputs/apk/debug/app-debug.apk
```

### المتطلبات

- وجود أداة `adb` في PATH (جزء من Android SDK Platform Tools)
- جهاز Android متصل عبر USB مع تفعيل "تصحيح USB" (USB Debugging)
- أو محاكي Android يعمل

---

## 4. سير العمل في GitHub Actions

ملف: `.github/workflows/build-apk.yml`

يقوم السير العمل بـ:
1. clonng المستودع من الفرع `arena/6b69a15d-tammtool`
2. إعداد JDK 17 عبر `actions/setup-java@v4`
3. **تثبيت Android SDK يدوياً عبر curl** من `dl.google.com` (بدلاً من الإجراء الجاهز الذي يفشل)
4. قبول التراخيص وتثبيت `platform-tools`، `android-35`، `build-tools-35.0.0`
5. بناء Debug APK لتطبيق `طلبات الأفغاني` (marketer)
6. رفع ملف APK كartifact يمكن تحميله من صفحة Actions في GitHub

---

## ملاحظات هامة

- ملفات `.apk`، `.aab`، `.keystore` مستبعدة من Git عبر `.gitignore`
- Android SDK يُثبّت محلياً فقط ولا يُرفع إلى المستودع
- لبناء نسخة Release موقعة، استخدم `scripts/sign-apk.sh` بعد البناء
