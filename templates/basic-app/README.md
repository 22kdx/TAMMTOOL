# قالب تطبيق أساسي (Basic App Template)

قالب أولي لإنشاء تطبيق Android بسيط باللغة Kotlin جاهز للبناء والتوقيع والنشر.

## محتويات القالب

```
basic-app/
├── build.gradle.kts                 # إعدادات الوحدة (المستوى الأدنى)
├── settings.gradle.kts              # تعريف الوحدات
├── AndroidManifest.xml              # بيان التطبيق (الأذونات، الأنشطة، ...)
├── res/
│   ├── layout/
│   │   └── activity_main.xml        # واجهة الشاشة الرئيسية
│   ├── values/
│   │   ├── strings.xml              # نصوص التطبيق
│   │   └── colors.xml               # ألوان التطبيق
│   └── mipmap-anydpi-v26/
│       └── ic_launcher.xml          # أيقونة التطبيق
├── src/main/java/com/tammtool/app/
│   └── MainActivity.kt              # نقطة دخول التطبيق (بلغة Kotlin)
└── proguard-rules.pro               # قواعد تصغير الشيفرة (ProGuard/R8)
```

## كيفية الاستخدام

1. انسخ القالب إلى مشروعك الجديد:
   ```bash
   cp -r templates/basic-app my-app
   cd my-app
   ```
2. افتح المشروع في Android Studio وقم بـ "Sync Now".
3. شغّل البناء:
   ```bash
   ./gradlew assembleDebug
   ```
4. ثبت الملف الناتج على الجهاز:
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

## تخصيص القبل

- عدّل `applicationId` و `versionCode` و `versionName` في `build.gradle.kts`.
- عدّل حزمة التطبيق (`package` / `namespace`) في `AndroidManifest.xml` و `build.gradle.kts`.
- أضف الأذونات المطلوبة في `AndroidManifest.xml` (مثل الإنترنت، الكاميرا، الموقع).

بعد أن يصبح التطبيق جاهزًا، راجع دوائر العمل في `docs/` للبناء والتوقيع والنشر.