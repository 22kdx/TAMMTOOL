# دورة العمل: توقيع ملف APK (Sign APK Workflow)

التوقيع الرقمي خطوة إلزامية قبل نشر أي تطبيق على متجر Google Play أو تثبيت نسخة الإصدار على الأجهزة. يضمن التوقيع أن التطبيق stammt من المطور الحقيقي ولم يتم التعديل عليه.

## الخطوة 1: إنشاء ملف Keystore (إذا لم يكن موجودًا)

استخدم أداة `keytool` المرفقة مع JDK لإنشاء مفتاح خاص وشهادة:

```bash
keytool -genkeypair -v \
  -keystore release-keystore.jks \
  -alias release-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

سيطلب منك الأداة إدخال:
- كلمة مرور keystore
- اسم겐.key (alias)
- معلومات المطور (الاسم، الوحدة، المدينة، الدولة، الرمز البريدي)

> ⚠️ احفظ ملف `.jks` وكلمات المرور في مكان آمن. إذا فقدت keystore، لن تتمكن من تحديث التطبيق على Google Play أبدًا.

## الخطوة 2: إضافة إعدادات التوقيع إلى Gradle

في ملف `build.gradle.kts` للوحدة (`app`):

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("../keystore/release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "default-store-pass"
            keyAlias = System.getenv("KEY_ALIAS") ?: "release-key"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "default-key-pass"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

ضع ملف keystore في مجلد آمن مثل `keystore/release-keystore.jks` وأضفه إلى `.gitignore` لتجنب رفعه إلى المستودع.

## الخطوة 3: بناء النسخة الموقعة

```bash
./gradlew assembleRelease
```

سيتم إخراج ملف APK الموقّع في:

```
app/build/outputs/apk/release/app-release.apk
```

## الخطوة 4: التحقق من التوقيع

```bash
apksigner verify --verbose app/build/outputs/apk/release/app-release.apk
```

إذا ظهرت عبارة "VERIFIED"، فإن الملف موقع بشكل صحيح وجاهز للتوزيع.

## الخطوة 5: محاذاة الملف (Zipalign) — اختياري ولكن مستحسن

```bash
zipalign -v -p 4 app-release-unsigned.apk app-release-aligned.apk
```

ثم signing على الملف المحاذى. في معظم الحالات، يقوم Gradle بهذه الخطوة تلقائيًا عند بناء Release.

## الخطوة 6: توزيع النسخة الموقعة

- **تثبيت تجريبي على جهاز:**
  ```bash
  adb install -r app-release.apk
  ```

- **رفع إلى Google Play Console:** استخدم ملف AAB أو APK الموقّع عبر صفحة release.

- **توزيع عبر Firebase App Distribution:**
  ```bash
  firebase appdistribution:distribute app-release.apk \
    --app 1:123456789:android:abcdef \
    --groups testers
  ```

## تحذيرات أمنية

1. لا ترفع ملف `keystore.jks` أو كلمات المرور إلى GitHub.
2. استخدم متغيرات البيئة (Environment Variables) أو Secrets في CI/CD لتمرير كلمات المرور.
3. احتفظ بنسخة احتياطية من keystore في مكان خارجي آمن.

بعد التوقيع والتحقق، يمكنك نشر التطبيق عبر دورة [نشر على Google Play](./workflow-publish-play-store.md).