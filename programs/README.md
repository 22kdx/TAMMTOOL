# البرامج والأدوات المطلوبة (Programs)

تحتوي هذه القائمة على البرامج الأساسية التي يجب تثبيتها قبل البدء في بناء تطبيقات APK احترافية.

## 1. بيئات التطوير المتكاملة (IDEs)

| البرنامج | الغرض | الرابط الرسمي |
|---------|-------|--------------|
| Android Studio | بيئة التطوير الرسمية لتطبيقات Android (تُستخدم للبناء والتصحيح والنشر) | https://developer.android.com/studio |
| Visual Studio Code | محرر خفيف لتعديل الأكواد وملفات الإعدادات مع إضافات Android و Kotlin | https://code.visualstudio.com |
| IntelliJ IDEA | بديل قوي لتطوير Kotlin و Java وأندرويد | https://www.jetbrains.com/idea |

> التوصية: استخدم **Android Studio** كبيئة رئيسية لبناء APK، لأنه يضم Android SDK و Build Tools و Emulator وأدوات التحليل المدمجة.

## 2. حزمة تطوير Java (JDK)

| الإصدار | الملاحظات |
|---------|-----------|
| JDK 17 (LTS) | الإصدار الموصى به من Google لأنظمة Android الحديثة (AGP 8.x وما فوق) |
| JDK 11 | مدعوم في إصدارات أقدم من Android Gradle Plugin |
| JDK 21 | تجريبي لبعض الإصدارات الحديثة، يُVerify توافق AGP قبل الاستخدام |

توزيعات مقترحة: **Eclipse Temurin (Adoptium)** أو **Amazon Corretto** أو **Oracle JDK**.

## 3. Android SDK وأدوات السطر 명령 (Command Line Tools)

المكونات التي يجب تثبيتها عبر **SDK Manager** في Android Studio:

- Android SDK Platform (أحدث إصدار مستقر،例如 Android 15 / API 35)
- Android SDK Build-Tools (أحدث إصدار)
- Android Emulator
- Android SDK Platform-Tools (يحتوي على `adb` و `fastboot`)
- Google Play Services / Google Repository
- Sources for Android Server (اختياري)

متغيرات البيئة المهمة التي يجب إضافتها إلى `PATH`:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
```

## 4. أدوات البناء والتوقيع

| الأداة | الغرض |
|-------|-------|
| Gradle | أداة automatización البناء المستخدمة من قبل Android Gradle Plugin |
| apksigner | توقيع ملف APK بشهادة digitally (توجد في build-tools) |
| jarsigner / keytool | إنشاء وإدارة ملفات keystore والتوقيع |
| zipalign | تحسين محاذاة الملفات داخل APK لتقليل استهلاك الذاكرة |
| CMake / NDK | لبناء الشيفرة الأصلية (C/C++) إذا كان التطبيق يستخدم NDK |

## 5. المحاكاة والأجهزة الحقيقية

| الأداة | الغرض |
|-------|-------|
| Android Emulator (مدمج في Android Studio) | اختبار التطبيقات على أجهزة افتراضية (AVD) |
| Genymotion | محاكي سريع كبديل للمحاكي الرسمي |
| ADB (Android Debug Bridge) | ربط الجهاز بالحاسوب، تثبيت APK، سحب السجلات (logcat) |
| جهاز Android حقيقي | للاختبار النهائي قبل النشر (يُفضل الاتصال عبر USB ووضع Developer Options) |

## 6. أنظمة التحكم في الإصدار والأتمتة

| الأداة | الغرض |
|-------|-------|
| Git | إدارة الشيفرة المصدرية والإصدارات |
| GitHub / GitLab | استضافة المستودعات وتشغيل خطوط CI/CD |
| Fastlane | أتمتة البناء والتوقيع والنشر على المتاجر |
| Firebase CLI | النشر على Firebase App Distribution واختبار Crashlytics |

## cómo البدء السريع

```bash
# 1. تثبيت Android Studio و JDK 17
# 2. تشغيل SDK Manager وتثبيت المنصة dernières و Build-Tools
# 3. إضافة مسارات SDK إلى متغيرات البيئة (PATH)
# 4. التحقق من التثبيت:
adb version
java -version
./gradlew --version
```

بعد تثبيت البرامج، انتقل إلى [systems/README.md](../systems/README.md) لاختيار نظام البناء المناسب، ثم [plugins/README.md](../plugins/README.md) لتفعيل الإضافات المفيدة.