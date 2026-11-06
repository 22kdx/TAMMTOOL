# دورة العمل: بناء ملف APK (Build APK Workflow)

هذه الدورة توضح الخطوات التي يجب اتباعها لتحويل شيفرة التطبيق إلى ملف APK جاهز للتثبيت على أجهزة Android.

## الخطوة 1: تجهيز البيئة

تأكد من تثبيت البرامج المذكورة في [programs/README.md](../programs/README.md) وتحقق من متغيرات البيئة:

```bash
java -version          # يجب أن يظهر JDK 17 أو أحدث
adb version            # يجب أن يظهر إصدار Android Debug Bridge
./gradlew --version    # يجب أن يظهر إصدار Gradle و Android Gradle Plugin
```

## الخطوة 2: clone أو إنشاء المشروع

```bash
# clone من المستودع (إذا كان عن بعد)
git clone <رابط-المستودع>
cd <المشروع>

# أو إنشاء مشروع جديد من القالب
cp -r ../templates/basic-app ./ my-app
cd my-app
```

## الخطوة 3: مزامنة المشروع مع Gradle

افتح المشروع في Android Studio وانقر على **"Sync Now"**، أو شغّل الأمر التالي من سطر الأوامر:

```bash
./gradlew androidDependencies
```

هذا يضمن تحميل جميع التبعيات (dependencies) وإعداد البيئة بشكل صحيح.

## الخطوة 4: بناء نسخة التصحيح (Debug APK)

```bash
./gradlew assembleDebug
```

سيتم إخراج الملف في المسار التالي:

```
app/build/outputs/apk/debug/app-debug.apk
```

يمكن تثبيته مباشرة على جهاز متصل عبر USB:

```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

## الخطوة 5: بناء نسخة الإصدار (Release APK)

نسخة الإصدار تتطلب توقيعًا (Signing) لضمان Sicherheit وأصالة التطبيق.

```bash
./gradlew assembleRelease
```

سيتم إخراج الموقع(unsigned) في:

```
app/build/outputs/apk/release/app-release-unsigned.apk
```

## الخطوة 6: توقيع ملف APK

راجع دورة [توقيع APK](./workflow-sign-apk.md) لمعرفة كيفية توقيع الملف باستخدام `apksigner` وملف keystore.

## الخطوة 7: التحقق من الملف الناتج

```bash
# التحقق من التوقيع
apksigner verify --verbose app-release.apk

# عرض معلومات الملف
ls -lh app-release.apk
```

## ملخص مسارات المخرجات

| نوع البناء | مسار الملف الناتج |
|-----------|------------------|
| Debug APK | `app/build/outputs/apk/debug/app-debug.apk` |
| Release APK (unsigned) | `app/build/outputs/apk/release/app-release-unsigned.apk` |
| Release APK (signed) | `app/build/outputs/apk/release/app-release.apk` |
| Android App Bundle (AAB) | `app/build/outputs/bundle/release/app-release.aab` |

> ملاحظة: للنشر على **متجر Google Play**، يُفضل رفع ملف **AAB** وليس APK، لأن Google Play يقوم بتحسين وتقسيم التطبيق حسب جهاز المستخدم (App Bundles).

بعد البناء والتوقيع، يمكنك الانتقال إلى دورة [نشر التطبيق على Google Play](./workflow-publish-play-store.md) أو توزيعه تجريبيًا عبر Firebase App Distribution.