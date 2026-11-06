# أدوات سطر الأوامر (Command Line Tools)

هذه الصفحة توثق جميع أدوات سطر الأوامر (CLI) المستخدمة في بناء واختبار وتوقيع ونشر تطبيقات Android APK/AAB من terminal بدون الحاجة لفتح Android Studio.

## 1. أدوات Android SDK الأساسية (في مجلد platform-tools)

| الأداة | المسار التقريبي | الغرض |
|--------|----------------|-------|
| `adb` | `$ANDROID_HOME/platform-tools/adb` | Android Debug Bridge — ربط الأجهزة، تثبيت APK، سحب السجلات (logcat) |
| `fastboot` | `$ANDROID_HOME/platform-tools/fastboot` | التمهيد السريع (fastboot) لفلاش صور النظام والاسترداد |
| `systrace` | `$ANDROID_HOME/platform-tools/systrace` | تحليل أداء النظام والشاشة |
| `bbm` | `$ANDROID_HOME/platform-tools/battery-histories` | تحليل استهلاك البطارية |

## 2. أدوات البناء والتوقيع (في مجلد build-tools)

| الأداة | المسار التقريبي | الغرض |
|--------|----------------|-------|
| `apksigner` | `$ANDROID_HOME/build-tools/<version>/apksigner` | توقيع ملفات APK/AAB والتحقق من التوقيع |
| `zipalign` | `$ANDROID_HOME/build-tools/<version>/zipalign` | محاذاة ملفات APK لتقليل استهلاك الذاكرة |
| `aapt2` | `$ANDROID_HOME/build-tools/<version>/aapt2` | معالجة موارد Android (الملفات المدمجة) |
| `aidl` | `$ANDROID_HOME/build-tools/<version>/aidl` | واجهة تعريف Android (AIDL) للاتصال بين العمليات |
| `llvm-rs-cc` | `$ANDROID_HOME/build-tools/<version>/llvm-rs-cc` | ترجمة شيفرة RenderScript (مهمل في الإصدارات الحديثة) |

## 3. أدوات سطر الأوامر من SDK Command Line Tools

| الأداة | المسار التقريبي | الغرض |
|--------|----------------|-------|
| `sdkmanager` | `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager` | تثبيت وتحديث مكونات Android SDK (المنصات، build-tools، المحاكيات، ...) |
| `avdmanager` | `$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager` | إدارة الأجهزة الافتراضية (AVD) للمحاكاة |
| `apkanalyzer` | `$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer` | تحليل حجم ومحتويات ملف APK/AAB |
| `retrace` | `$ANDROID_HOME/cmdline-tools/latest/bin/retrace` | إعادة تتبع التتبع stack traces المفقود (obfuscated) |

## 4. أدوات Java و JDK

| الأداة | الغرض |
|--------|-------|
| `java` | تشغيل تطبيقات Java |
| `javac` | مترجم لغة Java |
| `keytool` | إنشاء وإدارة ملفات keystore والشهادات الرقمية |
| `jarsigner` | توقيع ملفات JAR و APK (بديل للأقدم من apksigner) |
| `jar` | إنشاء وإدارة ملفات JAR |

## 5. أدوات Gradle

| الأداة | الغرض |
|--------|-------|
| `./gradlew` | غلاف Gradle لمشروع Android (المفضل) |
| `gradle` | تثبيت Gradle بشكل عام على النظام |
| `./gradlew tasks` | عرض جميع المهام المتاحة في المشروع |
| `./gradlew dependencies` | عرض شجرة التبعيات (dependencies) |
| `./gradlew signingReport` | تقرير إعدادات التوقيع لجميع أنواع البناء |

## 6. أدوات Firebase

| الأداة | الغرض |
|--------|-------|
| `firebase` | واجهة سطر أوامر Firebase للتوزيع، الاستضافة، الدوال السحابية، ... |
| `flutterfire` | أدوات Firebase لتطبيقات Flutter (إذا تم استخدامها) |

## 7. أدوات التحليل والفحص (Analysis & Inspection)

| الأداة | الغرض |
|--------|-------|
| `apkanalyzer` | تحليل حجم APK، عدد الأساليب (methods)، الموارد،사와 التوقيع |
| `leakcanary` | مكتبة لكشف تسرب الذاكرة (تُستخدم داخل التطبيق، وليس CLI خالص) |
| `proguardguard` | تحليل قواعد ProGuard/R8 |
| `dexdump` | عرض محتويات ملفات DEX (dalvik executable) |
| `strings` | استخراج النصوص من الملفات الثنائية |

## 8. أدوات CI/CD من سطر الأوامر

| الأداة | الغرض |
|--------|-------|
| `gh` | واجهة GitHub CLI لإدارة المستودعات، الطلبات، والعمليات |
| `glab` | واجهة GitLab CLI |
| `fastlane` | أتمتة البناء والتوقيع والنشر (راجع ملف fastlane) |
| `bitrise` | واجهة Bitrise CLI للبناء السحابي |

## 9. أوامر سطر الأوامر الشائعة لمطور Android

### فحص الأجهزة المتصلة
```bash
adb devices
adb devices -l
```

### تثبيت APK على الجهاز
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/release/app-release.apk  # -r للتحديث بدون إزالة البيانات
```

### سحب السجلات (Logcat)
```bash
adb logcat
adb logcat -s TAG_NAME  # فلترة حسب الوسم (tag)
adb logcat -d > logcat.txt  # إخراج السجلات إلى ملف والخروج
```

### مسح بيانات التطبيق
```bash
adb shell pm clear com.tammtool.app
```

### إعادة تشغيل الجهاز
```bash
adb reboot
adb reboot bootloader  # الدخول إلى وضع Fastboot
```

### إدارة المحاكيات (AVD)
```bash
avdmanager list avd        # عرض الأجهزة الافتراضية المتاحة
avdmanager create avd -n my_avd -k "system-images;android-35;google_apis_playstore;x86_64"
emulator -avd my_avd     # تشغيل المحاكي
```

### تثبيت مكونات SDK
```bash
sdkmanager "platforms;android-35"
sdkmanager "build-tools;34.0.0"
sdkmanager "platform-tools"
sdkmanager "emulator"
sdkmanager --list  # عرض جميع الحزم المتاحة
```

### توقيع APK
```bash
apksigner sign --ks keystore/release-keystore.jks \
  --ks-key-alias release-key \
  --out app-release.apk app-release-unsigned.apk

apksigner verify --verbose app-release.apk
```

### محاذاة APK
```bash
zipalign -v -p 4 app-release-unsigned.apk app-release-aligned.apk
```

### تحليل حجم APK
```bash
apkanalyzer apk app-release.apk
apkanalyzer apk files app-release.apk
apkanalyzer apk dex app-release.apk
```

### إنشاء Keystore
```bash
keytool -genkeypair -v \
  -keystore release-keystore.jks \
  -alias release-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### تشغيل مهام Gradle
```bash
./gradlew assembleDebug
./gradlew assembleRelease
./gradlew bundleRelease
./gradlew installDebug  # بناء وتثبيت على الجهاز المتصل
./gradlew uninstallAll   # إزالة جميع نسخ التطبيق من الجهاز
./gradlew test           # اختبارات الوحدات
./gradlew connectedAndroidTest  # اختبارات واجهة المستخدم على الجهاز
./gradlew lint           # فحص أخطاء Android Lint
```

## 10. مثال سكريبت 집합 للأوامر (All-in-One)

انظر إلى ملف `scripts/build-apk.sh` و `scripts/sign-apk.sh` و `scripts/check-env.sh` في جذر المستودع لأوامر مجمعة وجاهزة للاستخدام.

## 11. متغيرات البيئة الضرورية

أضف هذه المتغيرات إلى ملف `.bashrc` أو `.zshrc` أو `.profile`:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
export JAVA_HOME=$HOME/.sdkman/candidates/java/current
export PATH=$PATH:$JAVA_HOME/bin
```

بعد التعديل، شغّل:
```bash
source ~/.bashrc  # أو source ~/.zshrc
```

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [مكتبات Android و Jetpack](../libraries/README.md) لإضافة التبعيات للتطبيق، أو [أنظمة CI/CD](../ci-cd/README.md) لإعداد خطوط البناء والنشر التلقائي.