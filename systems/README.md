# أنظمة البناء والتشغيل والاختبار والنشر (Systems)

هذه الصفحة توثق الأنظمة التي تُستخدم في دورة حياة بناء تطبيق Android حتى الحصول على ملف APK احترافي وجاهز للإنتاج.

## 1. نظام البناء الرئيسي: Gradle + Android Gradle Plugin (AGP)

Gradle هو المحرك الافتراضي لبناء تطبيقات Android. يُستخدم مع **Android Gradle Plugin** لإدارة التجميع، الموارد، التوقيع، والإصدار.

ملفات البناء الأساسية:
- `settings.gradle` / `settings.gradle.kts` — تعريف الوحدات (modules) في المشروع
- `build.gradle` (على مستوى المشروع) — إعدادات AGP والمستودعات (repositories)
- `build.gradle` (على مستوى الوحدة `app`) — إعدادات التطبيق: `compileSdk`، `minSdk`، `targetSdk`، `versionCode`، `versionName`، `signingConfig`، `buildTypes`، و `productFlavors`

مثال minimal على `build.gradle.kts` للوحدة:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.tammtool.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.tammtool.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("../keystore/release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
```

أوامر البناء الشائعة:
```bash
# بناء نسخة تصحيح (Debug)
./gradlew assembleDebug

# بناء نسخة إصدار (Release) موقعة
./gradlew assembleRelease

# بناء وتوقيع ونشر على المتجر (إذا تم إعداد Fastlane/GitHub Actions)
./gradlew bundleRelease
```

## 2. أنظمة التكامل والنشر المستمر (CI/CD)

| النظام | المنصة | الملاحظات |
|-------|--------|-----------|
| GitHub Actions | GitHub | مجاني للمستودعات العامة، يدعم بناء Android وتوقيع APK ونشره |
| GitLab CI/CD | GitLab | مرن للاستضافة الذاتية أو السحابية |
| Bitrise | سحابي | مخصص لبناء تطبيقات الجوال (iOS/Android) |
| Codemagic | سحابي | دعم قوي لبناء Flutter و Android و iOS |
| Fastlane | محلي / CI |'automation للبناء والتوقيع والنشر على Google Play و Firebase |

مثال سير عمل GitHub Actions لبناء APK (يُوضع في `.github/workflows/build-apk.yml`):

```yaml
name: Build Release APK

on:
  push:
    tags: ["v*"]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin
      - name: Build Release APK
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: ./gradlew assembleRelease
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: app/build/outputs/apk/release/app-release.apk
```

## 3. نظام الاختبار (Testing System)

| النوع | الأداة | الغرض |
|------|-------|-------|
| اختبارات وحدات (Unit Tests) | JUnit 5 + Kotlin Test | اختبار المنطق البرمجي دون واجهة |
| اختبارات واجهة المستخدم (UI Tests) | Espresso | اختبار التفاعل مع الشاشات والأزرار |
| اختبارات تلقائية على أجهزة حقيقية | Firebase Test Lab | اختبار على dozens من الأجهزة الحقيقية والمحاكية |
| تحليل الشيفرة الثابتة | Detekt / Ktlint / Lint | اكتشاف الأخطاء ونمط الكود قبل البناء |

أوامر الاختبار:
```bash
./gradlew test             # اختبارات الوحدات
./gradlew connectedAndroidTest  # اختبارات UI على جهاز/محاكيnected
./gradlew lint             # فحص أخطاء Android Lint
```

## 4. نظام التوقيع والتوزيع (Signing & Distribution)

| المرحلة | الأداة | الغرض |
|-------|-------|-------|
| إنشاء الشهادة | keytool / Android Studio | إنشاء ملف `.keystore` أو `.jks` للمفتاح الخاص |
| التوقيع | apksigner / jarsigner | توقيع ملف APK_release (إلزامي لنشر على Google Play) |
| المحاذاة | zipalign | تحسين حجم واستهلاك ذاكرة APK |
| التوزيع الداخلي | Firebase App Distribution | إرسال نسخ تجريبية للمختبرين قبل النشر الرسمي |
| النشر الرسمي | Google Play Console | نشر النسخة النهائية للمستخدمين |

## 5. systems الحالية في هذا المستودع

نحن نتبنى النظام التالي كافتراضي:

- **البناء:** Gradle 8.x + Android Gradle Plugin 8.x
- **اللغة:** Kotlin (المفضلة) مع دعم Java
- **النظام الأساسي للتجميع:** Android SDK API 35 (targetSdk 35)
- **CI/CD:** GitHub Actions (ऐच्छिक)
- **التوقيع:** ملف Keystore خاص + apksigner
- **التوزيع:** Google Play Console و Firebase App Distribution

بعد مراجعة هذا الملف، انتقل إلى [plugins/README.md](../plugins/README.md) لتعرف الإضافات التي تُركب على أنظمة البناء أعلاه.