# الإضافات والكماليات والملحقات (Plugins & Add-ons & Extensions)

هذا الملف هو الدليل الشامل لكل الإضافات والكماليات والملحقات (Plugins, Add-ons, Extensions) التي تُستخدم في بناء تطبيقات APK احترافية لنظام Android، مصنفة حسب استخدامها.

## فهرس المحتويات

| الفئة | المسار | ما تحتويه |
|-------|--------|-----------|
| [إضافات Gradle](./plugins/gradle/README.md) | `plugins/gradle/` | إضافات البناء، الجودة، Firebase، التوقيع، النشر |
| [إضافات Android Studio / IntelliJ](./plugins/android-studio/README.md) | `plugins/android-studio/` | إضافات بيئة التطوير الرسمية |
| [إضافات Visual Studio Code](./plugins/vscode/README.md) | `plugins/vscode/` | إضافات المحرر الخفيف لتطوير Android |
| [إضافات Fastlane](./plugins/fastlane/README.md) | `plugins/fastlane/` | أتمتة البناء والتوقيع والنشر على المتاجر |
| [أدوات سطر الأوامر (CLI)](./plugins/cli/README.md) | `plugins/cli/` | أدوات terminal للبناء، الفحص، التصحيح، التوقيع |
| [مكتبات Android و Jetpack](./plugins/libraries/README.md) | `plugins/libraries/` | AndroidX, Jetpack, Material, Networking, Database, DI, ... |
| [أنظمة CI/CD](./plugins/ci-cd/README.md) | `plugins/ci-cd/` | GitHub Actions, GitLab CI, Bitrise, Codemagic, ... |
| [التحليلات وال crash reporting](./plugins/analytics/README.md) | `plugins/analytics/` | Firebase Analytics, Crashlytics, Mixpanel, Amplitude, ... |
| [الأمان والحماية](./plugins/security/README.md) | `plugins/security/` | ProGuard/R8, SafetyNet, App Check, تشفير, keystore, ... |
| [اختبار وضمان الجودة](./plugins/testing/README.md) | `plugins/testing/` | JUnit, Espresso, UI Automator, Detekt, Ktlint, Lint, ... |
| [التصميم وواجهات المستخدم](./plugins/design/README.md) | `plugins/design/` | Material Design, Compose, MotionLayout, icons, ... |

---

## نظرة سريعة على أهم الإضافات الموصى بها

للمشروع الاحترافي ابدأ minimal بهذه الحزمة:

### 1. إضافات البناء الأساسية (Gradle)
- `com.android.application` — بناء تطبيق APK/AAB
- `org.jetbrains.kotlin.android` — دعم لغة Kotlin
- `com.google.gms.google-services` — خدمات Firebase
- `com.google.firebase.crashlytics` — الإبلاغ عن الأعطال

### 2. إضافات الجودة والتحليل الثابت
- `io.gitlab.arturbosch.detekt` — تحليل ثابت لشيفرة Kotlin
- `org.jlleitschuh.gradle.ktlint` — تنسيق شيفرة Kotlin تلقائياً
- `com.android.tools.build:gradle` — Android Gradle Plugin (أساسي)

### 3. إضافات النشر والتوزيع
- `com.github.triplet.play` — نشر على Google Play Console من Gradle
- Fastlane (`gradle`, `signing`, `google_play`, `firebase_app_distribution`)

### 4. إضافات Android Studio الموصى بها
- Kotlin (مدمج)
- Firebase Assistant
- JSON to Kotlin Class
- CodeGlance, Key Promoter X, Android WiFi ADB

### 5. مكتبات runtime الأساسية
- AndroidX Core, AppCompat, Material Components, ConstraintLayout
- Jetpack Navigation, ViewModel, LiveData, Room, WorkManager, Paging
- Retrofit / OkHttp / Coil / Coroutines / Flow

---

## كيفية إضافة إضافة Gradle جديدة

في ملف `build.gradle.kts` (على مستوى المشروع):

```kotlin
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
    id("io.gitlab.arturbosch.detekt") version "1.23.0" apply false
}
```

وفي ملف الوحدة `app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("io.gitlab.arturbosch.detekt")
}
```

---

## ملاحظة هامة

جميع الإضافات المذكورة خاضعة لتراخيصها الأصلية. تأكد من مراجعة الترخيص قبل استخدامها في مشاريع تجارية. يتم تحديث هذه القائمة باستمرار مع تطور نظام Android البيئي.

---

## ملخص سريع للبدء

1. راجع [إضافات Gradle](./plugins/gradle/README.md) لإعداد ملفات `build.gradle.kts`.
2. راجع [إضافات Android Studio](./plugins/android-studio/README.md) لتثبيت الإضافات في بيئة التطوير.
3. راجع [إضافات VS Code](./plugins/vscode/README.md) إذا كنت تستخدم المحرر الخفيف.
4. راجع [أدوات CLI](./plugins/cli/README.md) لأتمتة المهام من سطر الأوامر.
5. راجع [مكتبات Android](./plugins/libraries/README.md) لإضافة التبعيات (dependencies) للتطبيق.
6. راجع [CI/CD](./plugins/ci-cd/README.md) لإعداد خطوط البناء والنشر التلقائي.
7. راجع [الأمان](./plugins/security/README.md) لحماية التطبيق والشيفرة.
8. راجع [الاختبار](./plugins/testing/README.md) لضمان جودة التطبيق قبل النشر.